# TODO: fix weird error when disconnecting from server and only if you moved??: _remove_node_cache: Condition "!pinfo" is true. Continuing.
# https://github.com/godotengine/godot/issues/92358

extends Window


# PARAM
var worlds
var world_dir_path

@export var _players: Node
@export var _items: Node
@export var _overworld: Node
@export var client_ui_scene: PackedScene
var main
var func_u
var modules
var world_config = ConfigFile.new()
var server_ip
var server_port
var server_node
var smapi = SceneMultiplayer.new()


func _enter_tree():
	main = worlds.main
	func_u = main.modules.func_u
	modules = {
		"players": _players,
		"items": _items,
		"overworld": _overworld,
	}
	
	smapi.peer_authenticating.connect(func(p):
		if server_node != null:
			while not smapi.get_unique_id() in server_node.smapi.get_authenticating_peers(): await get_tree().process_frame
			server_node.peers[smapi.get_unique_id()] = { "user_id": "-1", "username": "Local Player" }
			server_node.smapi.complete_auth(smapi.get_unique_id())
			smapi.complete_auth(p)
		else:
			smapi.send_auth(p, JSON.stringify({ "action": "create_ticket", "user_id": main.modules.pocketbase.user_id }).to_utf8_buffer())
	)
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		if data.err != null:
			smapi.disconnect_peer(p)
		else:
			var ticket_id = data.ret
			var res = await main.modules.pocketbase.api_GET("collections/server_tickets/records/%s" % ticket_id, true)
			if res.response_code != 200:
				smapi.disconnect_peer(p)
			else:
				smapi.send_auth(p, JSON.stringify({ "action": "redeem_ticket", "ticket_id": ticket_id, "ticket_key": res.body.key }).to_utf8_buffer())
				smapi.complete_auth(p)
	)
	smapi.connected_to_server.connect(_on_connected_to_server)
	smapi.server_disconnected.connect(_on_server_disconnected)
	get_tree().set_multiplayer(smapi, get_path())


func _exit_tree():
	if smapi.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		smapi.disconnect_peer(1)
	print("closing client")


func _ready():
	var err = func_u.ConfigFile_load(world_config, world_dir_path.path_join("world.cfg"))
	if err != null: func_u.unreacheable(err)
	
	if world_config.has_section_key("general", "server_world_dir_path"):
		var arr = worlds.active_servers.keys().filter(func(n): return n.world_dir_path == world_config.get_value("general", "server_world_dir_path"))
		if arr.is_empty():
			push_error("couldn't find local running server for world %s" % world_config.get_value("general", "server_world_dir_path"))
			queue_free()
			return
		
		server_node = arr[0]
		server_ip = "127.0.0.1"
		server_port = server_node.port
	else:
		server_ip = world_config.get_value("general", "server_ip")
		server_port = world_config.get_value("general", "server_port")
	
	print("starting client %s %d" % [server_ip, server_port])
	match OS.get_name():
		"Web":
			var mpeer = WebSocketMultiplayerPeer.new()
			mpeer.create_client("ws://%s:%d" % [server_ip, server_port])
			smapi.multiplayer_peer = mpeer
		_:
			var enet = ENetMultiplayerPeer.new()
			enet.create_client(server_ip, server_port)
			smapi.multiplayer_peer = enet


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		queue_free()


func _on_connected_to_server():
	print("connected to server %s with port %s" % [server_ip, server_port])
	var new_client_ui = client_ui_scene.instantiate()
	new_client_ui.client = self
	add_child(new_client_ui)


func _on_server_disconnected():
	print("disconnected from server")
	queue_free()


