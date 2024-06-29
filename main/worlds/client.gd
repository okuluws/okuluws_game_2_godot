# TODO: fix weird error when disconnecting from server and only if you moved??: _remove_node_cache: Condition "!pinfo" is true. Continuing.
# https://github.com/godotengine/godot/issues/92358

extends Window


# PARAM
var worlds
var world_dir_path
var server_node

@export var _players: Node
@export var _items: Node
@export var _overworld: Node
var modules
@export var client_ui_scene: PackedScene
@onready var main = worlds.main
var world_config = ConfigFile.new()
var server_ip
var server_port
var smapi = SceneMultiplayer.new()


func _on_tree_entered():
	modules = {
		"players": _players,
		"items": _items,
		"overworld": _overworld,
	}
	smapi.peer_authenticating.connect(func(p):
		smapi.complete_auth(p)
		if server_node != null:
			while not smapi.get_unique_id() in server_node.smapi.get_authenticating_peers(): await get_tree().process_frame
			server_node.peers[smapi.get_unique_id()] = { "user_id": "-1", "username": "Local Player" }
			server_node.smapi.complete_auth(smapi.get_unique_id())
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
	)
	smapi.connected_to_server.connect(_on_connected_to_server)
	smapi.server_disconnected.connect(_on_server_disconnected)
	get_tree().set_multiplayer(smapi, get_path())


func _ready():
	var err = main.modules.func_u.ConfigFile_load(world_config, world_dir_path.path_join("world.cfg"))
	if err != null:
		push_error(err)
		queue_free()
		return
	
	if server_node == null:
		server_ip = world_config.get_value("", "server_ip")
	else:
		server_port = world_config.get_value("", "server_port")
		server_ip = "127.0.0.1"
		server_port = server_node.port
	
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


func _on_connected_to_server():
	print("connected to server %s with port %s" % [server_ip, server_port])
	var new_client_ui = client_ui_scene.instantiate()
	new_client_ui.client = self
	add_child(new_client_ui)


func _on_server_disconnected():
	print("disconnected from server")
	smapi.multiplayer_peer = null
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if smapi.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			smapi.disconnect_peer(1)
		queue_free()
