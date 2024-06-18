# TODO: support web export (maybe learn WebRTC)

extends Window


# REQUIRED
var worlds
var world_dir_path
var server_ip
var server_port

@export var players: Node
@export var items: Node
@export var inventories: Node
@onready var main = worlds.main
signal load_queued
signal start_queued
signal save_queued
var enet = ENetMultiplayerPeer.new()
var smapi = SceneMultiplayer.new()
var crypto = Crypto.new()
var tickets = {}
var peer_users = {}


func _enter_tree():
	get_tree().set_multiplayer(smapi, get_path())
	
	print(DisplayServer.screen_get_size())
	print(DisplayServer.window_get_size())


func _exit_tree():
	save_queued.emit()
	smapi.multiplayer_peer = null
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())
	print("shutdown server")


func _ready():
	print("starting server with bind=%s port=%d" % [server_ip, server_port])
	
	enet.set_bind_ip(server_ip)
	enet.create_server(server_port)
	smapi.multiplayer_peer = enet
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		if data.has("user_id"):
			var res = await main.pb.api_POST("myapp/create_server_ticket", { "user_id": data.user_id })
			if res.response_code != 200:
				push_error("couldnt create server ticket");
				return
			tickets[res.body.ticked_id] = { "user_id": res.body.user_id, "username": res.body.username, "key": res.body.key, "date": Time.get_unix_time_from_system() }
			smapi.send_auth(p, res.body.ticked_id.to_utf8_buffer())
			return
		
		elif data.has("ticket_key") and data.has("ticket_id"):
			if crypto.constant_time_compare(data.ticket_key.to_utf8_buffer(), tickets[data.ticket_id].key.to_utf8_buffer()):
				peer_users[p] = { "user_id": tickets[data.ticket_id].user_id, "username": tickets[data.ticket_id].username }
				tickets.erase(data.ticket_id)
				smapi.complete_auth(p)
				print("ticket auth peer %d as %s" % [p, peer_users[p].username])
				return
			else:
				smapi.disconnect_peer(p)
				push_warning("ticket auth fail from peer %d (sus)" % p)
				return
		
	)
	smapi.peer_connected.connect(func(peer_id): print("connected user %s, peer %d" % [peer_users[peer_id].username, peer_id]))
	smapi.peer_authentication_failed.connect(func(peer_id):
		push_warning("peer %d failed auth" % peer_id)
		peer_users.erase(peer_id)
	)
	smapi.peer_disconnected.connect(func(peer_id):
		print("disconnected user %s, peer %d" % [peer_users[peer_id].username, peer_id])
		peer_users.erase(peer_id)
	)
	
	load_queued.emit()
	
	start_queued.emit()


func create_ticket(user_id: String, username: String) -> Dictionary:
	# technically this can collide🤓 - it's 512 bits brotha
	var ticket_id = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(64))
	
	# maybe thats not secure enough...
	var key = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(2048))
	
	tickets[ticket_id] = { "user_id": user_id, "username": username, "key": key, "created": Time.get_unix_time_from_system() }
	return { "id": ticket_id, "key": key }


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		worlds.close_server(self)
		
