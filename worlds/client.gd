# TODO: fix weird error when disconnecting from server and only if you moved??: _remove_node_cache: Condition "!pinfo" is true. Continuing.
# https://github.com/godotengine/godot/issues/92358

extends Window


signal started
signal stopping
const GameMain = preload("res://main.gd")
const source_directory = GameMain.Worlds.source_directory + "" # maybe make client directory in future
const Players = preload(source_directory + "players/main_client.gd")
const Items = preload(source_directory + "items/items_client.gd")
const Overworld = preload(source_directory + "overworld/main_client.gd")
@export var players: Players
@export var items: Items
@export var overworld: Overworld
@export var client_ui_scene: PackedScene
var game_main: GameMain
var world_directory: String
var world_config = ConfigFile.new()
var server_ip: String
var server_port: int
var server_node: GameMain.Worlds.Server
var smapi = SceneMultiplayer.new()


func init(p_game_main: GameMain, p_world_directory: String) -> void:
	game_main = p_game_main
	world_directory = p_world_directory
	
	game_main.func_u.load_config_file(world_config, world_directory.path_join("world.cfg"))
	if world_config.has_section_key("general", "server_world_directory"):
		server_node = game_main.worlds.active_servers[world_config.get_value("general", "server_world_directory")]
		server_ip = "127.0.0.1"
		server_port = server_node.port
	else:
		server_ip = world_config.get_value("general", "server_ip")
		server_port = world_config.get_value("general", "server_port")
	
	
	smapi.peer_authenticating.connect(func(p):
		if server_node != null:
			while not smapi.get_unique_id() in server_node.smapi.get_authenticating_peers(): await get_tree().process_frame
			server_node.peers[smapi.get_unique_id()] = { "user_id": "-1", "username": game_main.pocketbase.get_current_auth_username() if game_main.pocketbase.has_current_auth() else "Local Player" }
			server_node.smapi.complete_auth(smapi.get_unique_id())
			smapi.complete_auth(p)
		else:
			smapi.send_auth(p, JSON.stringify({ "action": "create_ticket", "user_id": game_main.pocketbase.current_auth_record_id }).to_utf8_buffer())
	)
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		if data.err != null:
			smapi.disconnect_peer(p)
			return
		
		var ticket_id = data.ret
		game_main.pocketbase.view_record("server_tickets", ticket_id, true).connect(func(err: GameMain.FuncU.OptionalString, result: GameMain.FuncU.OptionalDictionary):
			if err != null:
				smapi.disconnect_peer(p)
			else:
				smapi.send_auth(p, JSON.stringify({ "action": "redeem_ticket", "ticket_id": ticket_id, "ticket_key": result.val.key }).to_utf8_buffer())
				smapi.complete_auth(p)
		)
	)
	smapi.connected_to_server.connect(_on_connected_to_server)
	smapi.server_disconnected.connect(_on_server_disconnected)
	get_tree().set_multiplayer(smapi, get_path())
	players.init(self)
	items.init(self)


func start() -> void:
	print("starting client %s %d" % [server_ip, server_port])
	var m_peer: MultiplayerPeer
	match OS.get_name():
		"Web":
			m_peer = WebSocketMultiplayerPeer.new()
			m_peer.create_client("ws://%s:%d" % [server_ip, server_port])
		_:
			m_peer = ENetMultiplayerPeer.new()
			m_peer.create_client(server_ip, server_port)
	smapi.multiplayer_peer = m_peer
	started.emit()


func stop() -> void:
	stopping.emit()
	if smapi.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		smapi.disconnect_peer(1)
	print("stopped client")


func _exit_tree() -> void:
	stop()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		stop()


func _on_connected_to_server():
	print("connected to server %s with port %s" % [server_ip, server_port])
	var new_client_ui = client_ui_scene.instantiate()
	new_client_ui.client = self
	add_child(new_client_ui)


func _on_server_disconnected():
	print("disconnected from server")
	stop()
