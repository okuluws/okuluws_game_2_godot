# TODO: support web export (maybe learn WebRTC) see NOTES

extends Window


# REQUIRED
var worlds: Worlds
var world_dir_path: String

const Worlds = preload("worlds.gd")
const GameMain = Worlds.GameMain
signal world_saving
@export var _players: Node
@export var _items: Node
@export var _inventories: Node
@export var _overworld: Node
@onready var main: GameMain = worlds.main
var world_config = ConfigFile.new()
var bind_ip
var port
var smapi = SceneMultiplayer.new()
var tickets = {}
var peers = {}
var _crypto = Crypto.new()

class Modules:
	const Players = preload("players/main_server.gd")
	var players: Players
	const Items = preload("items/items_server.gd")
	var items: Items
	const Inventories = preload("inventories/main_server.gd")
	var inventories: Inventories
	const Overworld = preload("overworld/main_server.gd")
	var overworld: Overworld
var modules: Modules = Modules.new()


func _enter_tree():
	modules.players = _players
	modules.items = _items
	modules.inventories = _inventories
	modules.overworld = _overworld
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		match data.action:
			"create_ticket":
				var res = await main.modules.pocketbase.api_POST("myapp/create_server_ticket", { "user_id": data.user_id })
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


func _exit_tree():
	for p in smapi.get_peers():
		smapi.disconnect_peer(p)
	world_saving.emit()
	print("closing server")


func _ready():
	var err = main.modules.func_u.ConfigFile_load(world_config, world_dir_path.path_join("world.cfg"))
	if err != null:
		push_error(err)
		queue_free()
		return
	
	bind_ip = world_config.get_value("general", "bind_ip")
	port = world_config.get_value("general", "port")
	
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


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		queue_free()

