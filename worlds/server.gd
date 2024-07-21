# TODO: support web export (maybe learn WebRTC) see NOTES

extends Window


signal started
signal stopping
signal saving
const GameMain = preload("res://main.gd")
const source_directory = GameMain.Worlds.source_directory + "" # maybe make server directory in future
const Players = preload(source_directory + "players/main_server.gd")
const Items = preload(source_directory + "items/items_server.gd")
const Inventories = preload(source_directory + "inventories/main_server.gd")
const Overworld = preload(source_directory + "overworld/main_server.gd")
@export var players: Players
@export var items: Items
@export var inventories: Inventories
@export var overworld: Overworld
var game_main: GameMain
var world_directory: String
var world_config_file: String
var world_config = ConfigFile.new()
var bind_ip
var port
var smapi = SceneMultiplayer.new()
var tickets = {}
var peers = {}
var _crypto = Crypto.new()


## call after adding to scene tree
func init(p_game_main: GameMain, p_world_directory: String) -> void:
	game_main = p_game_main
	world_directory = p_world_directory
	world_config_file = world_directory.path_join("world.cfg")
	game_main.func_u.load_config_file(world_config, world_config_file)
	bind_ip = world_config.get_value("general", "bind_ip")
	port = world_config.get_value("general", "port")
	
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		match data.action:
			"create_ticket":
				game_main.pocketbase.request_api("/myapp/create_server_ticket", HTTPClient.METHOD_POST, { "user_id": data.user_id }, null, 200).connect(func(err: GameMain.FuncU.OptionalString, result: GameMain.FuncU.OptionalDictionary):
					if err != null:
						push_error("couldnt create server ticket for %s" % data.user_id)
						smapi.send_auth(p, JSON.stringify({ "err": null, "result": result.val.ticket_id }).to_utf8_buffer())
					else:
						tickets[result.val.ticked_id] = { "user_id": result.val.user_id, "username": result.val.username, "key": result.val.key, "created": Time.get_unix_time_from_system() }
						smapi.send_auth(p, JSON.stringify({ "err": "failed idk", "result": null }).to_utf8_buffer())
				)
			"redeem_ticket":
				if _crypto.constant_time_compare(data.ticket_key.to_utf8_buffer(), tickets[data.ticket_id].key.to_utf8_buffer()):
					peers[p] = { "user_id": tickets[data.ticket_id].user_id, "username": tickets[data.ticket_id].username }
					tickets.erase(data.ticket_id)
					smapi.complete_auth(p)
					print("ticket auth peer %d as %s" % [p, peers[p].username])
				else:
					smapi.disconnect_peer(p)
					print("ticket >%s< auth fail from peer %d (sus)" % [data.ticket_id, p])
			_:
				smapi.disconnect_peer(p)
				print("unknown request >%s< from peer %d (sus)" % [data.action, p])
	)
	smapi.peer_connected.connect(func(peer_id): print("connected user %s, peer %d" % [peers[peer_id].username, peer_id]))
	smapi.peer_authentication_failed.connect(func(peer_id):
		print("peer %d failed auth" % peer_id)
		peers.erase(peer_id)
	)
	smapi.peer_disconnected.connect(func(peer_id):
		print("disconnected user %s, peer %d" % [peers[peer_id].username, peer_id])
		peers.erase(peer_id)
	)
	get_tree().set_multiplayer(smapi, get_path())
	players.init(self)
	items.init(self)
	inventories.init(self)
	overworld.init(self)


func _exit_tree() -> void:
	stop()


func stop() -> void:
	saving.emit()
	stopping.emit()
	for p in smapi.get_peers():
		smapi.disconnect_peer(p)
	print("stopped server")


func start() -> void:
	print("starting server %s %d" % [bind_ip, port])
	var m_peer: MultiplayerPeer
	match OS.get_name():
		"Web":
			# NOTE: doesnt work on web yet
			m_peer = WebSocketMultiplayerPeer.new()
			m_peer.create_server(port)
		_:
			m_peer = ENetMultiplayerPeer.new()
			m_peer.set_bind_ip(bind_ip)
			m_peer.create_server(port)
	smapi.multiplayer_peer = m_peer
	started.emit()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		stop()
