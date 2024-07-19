# TODO: support web export (maybe learn WebRTC) see NOTES

extends Window


signal started
signal stopping
signal saving
const GameMain = preload("res://main.gd")
const src_dirpath = GameMain.Worlds.src_dirpath + "" # maybe make server directory in future
const Players = preload(src_dirpath + "players/main_server.gd")
const Items = preload(src_dirpath + "items/items_server.gd")
const Inventories = preload(src_dirpath + "inventories/main_server.gd")
const Overworld = preload(src_dirpath + "overworld/main_server.gd")
@export var players: Players
@export var items: Items
@export var inventories: Inventories
@export var overworld: Overworld
var game_main: GameMain
var world_dirpath: String
var world_config_filepath: String
var world_config = ConfigFile.new()
var bind_ip
var port
var smapi = SceneMultiplayer.new()
var tickets = {}
var peers = {}
var _crypto = Crypto.new()


## call after adding to scene tree
func init(p_game_main: GameMain, p_world_dirpath: String) -> void:
	game_main = p_game_main
	world_dirpath = p_world_dirpath
	world_config_filepath = world_dirpath + "world.cfg"
	var err = game_main.func_u.ConfigFile_load(world_config, world_config_filepath)
	if err != null:
		push_error(err)
		queue_free()
		return
	bind_ip = world_config.get_value("general", "bind_ip")
	port = world_config.get_value("general", "port")
	
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		match data.action:
			"create_ticket":
				var res = await game_main.pocketbase.api_POST("myapp/create_server_ticket", { "user_id": data.user_id })
				if res.response_code != 200:
					push_warning("couldnt create server ticket for %s" % data.user_id);
					smapi.send_auth(p, JSON.stringify({ "err": "failed idk", "ret": null }).to_utf8_buffer())
				else:
					tickets[res.body.ticked_id] = { "user_id": res.body.user_id, "username": res.body.username, "key": res.body.key, "created": Time.get_unix_time_from_system() }
					smapi.send_auth(p, JSON.stringify({ "err": null, "ret": res.body.ticket_id }).to_utf8_buffer())
			"redeem_ticket":
				if _crypto.constant_time_compare(data.ticket_key.to_utf8_buffer(), tickets[data.ticket_id].key.to_utf8_buffer()):
					peers[p] = { "user_id": tickets[data.ticket_id].user_id, "username": tickets[data.ticket_id].username }
					tickets.erase(data.ticket_id)
					smapi.complete_auth(p)
					print("ticket auth peer %d as %s" % [p, peers[p].username])
				else:
					smapi.disconnect_peer(p)
					push_warning("ticket >%s< auth fail from peer %d (sus)" % [data.ticket_id, p])
			_:
				smapi.disconnect_peer(p)
				push_warning("unknown request >%s< from peer %d (sus)" % [data.action, p])
	)
	smapi.peer_connected.connect(func(peer_id): print("connected user %s, peer %d" % [peers[peer_id].username, peer_id]))
	smapi.peer_authentication_failed.connect(func(peer_id):
		push_warning("peer %d failed auth" % peer_id)
		peers.erase(peer_id)
	)
	smapi.peer_disconnected.connect(func(peer_id):
		print("disconnected user %s, peer %d" % [peers[peer_id].username, peer_id])
		peers.erase(peer_id)
	)
	get_tree().set_multiplayer(smapi, get_path())
	inventories.init(self)


func _exit_tree():
	stop()


func stop() -> void:
	saving.emit()
	stopping.emit()
	for p in smapi.get_peers():
		smapi.disconnect_peer(p)
	print("stopped server")


func start():
	print("starting server %s %d" % [bind_ip, port])
	match OS.get_name():
		"Web":
			# NOTE: doesnt work on web yet
			var mpeer = WebSocketMultiplayerPeer.new()
			mpeer.create_server(port)
			smapi.multiplayer_peer = mpeer
		_:
			var enet = ENetMultiplayerPeer.new()
			enet.set_bind_ip(bind_ip)
			enet.create_server(port)
			smapi.multiplayer_peer = enet
	started.emit()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		stop()
