extends SubViewport


const IS_SERVER = true
@onready var pocketbase = $"/root/Main/Pocketbase"
var world_dir = null
var server_ip = null
var server_port = null
#var CONFIG_FILENAME: String
#var LEVEL_FILENAME: String

var log_filepath
var enet = ENetMultiplayerPeer.new()
var smapi = SceneMultiplayer.new()
var crypto = Crypto.new()
var tickets = {}
var peer_users = {}
signal load_queued
signal start_queued
signal save_queued


func _enter_tree():
	get_tree().set_multiplayer(smapi, get_path())


func _exit_tree():
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())


func _ready():
	log_filepath = world_dir.path_join("log.txt")
	FileAccess.open(log_filepath, FileAccess.WRITE)
	
	log_default("starting server with ip %s on port %d ..." % [server_ip, server_port])
	
	enet.set_bind_ip(server_ip)
	enet.create_server(server_port)
	smapi.multiplayer_peer = enet
	smapi.set_auth_callback(func(p, raw_data: PackedByteArray):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		if data.has("user_id"):
			var res = await pocketbase.api_POST("myapp/create_server_ticket", { "user_id": data.user_id })
			if res.response_code != 200: push_error("couldnt create server ticket"); return
			tickets[res.body.ticked_id] = { "user_id": res.body.user_id, "username": res.body.username, "token": res.body.token, "date": Time.get_unix_time_from_system() }
			smapi.send_auth(p, res.body.ticked_id.to_utf8_buffer())
			return
		
		elif data.has("ticket_token") and data.has("ticket_id"):
			if crypto.constant_time_compare(data.ticket_token.to_utf8_buffer(), tickets[data.ticket_id].token.to_utf8_buffer()):
				peer_users[p] = { "user_id": tickets[data.ticket_id].user_id, "username": tickets[data.ticket_id].username }
				tickets.erase(data.ticket_id)
				smapi.complete_auth(p)
				log_default("ticket auth peer %d as %s" % [p, peer_users[p].username])
				return
			else:
				smapi.disconnect_peer(p)
				push_warning("ticket auth fail from peer %d (sus)" % p)
				return
		
		print_debug("unknown request from peer %d, KICKED" % p)
		smapi.disconnect_peer(p)
	)
	smapi.peer_connected.connect(func(peer_id): log_default("connected user %s, peer %d" % [peer_users[peer_id].username, peer_id]))
	smapi.peer_authentication_failed.connect(func(peer_id):
		log_default("peer %d failed auth" % peer_id)
		peer_users.erase(peer_id)
	)
	smapi.peer_disconnected.connect(func(peer_id):
		log_default("disconnected user %s, peer %d" % [peer_users[peer_id].username, peer_id])
		peer_users.erase(peer_id)
	)
	
	load_queued.emit()
	
	start_queued.emit()
	
	log_default("starting server done.")


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		shutdown()


func log_default(msg):
	var s = "[Server][%s]%s" % [Time.get_time_string_from_system(), msg]
	print(s)
	var f = FileAccess.open(log_filepath, FileAccess.READ_WRITE)
	f.seek_end()
	f.store_line(s)
	f.close()


func shutdown():
	save_queued.emit()
	queue_free()
	log_default("shutdown server")

