extends SubViewport


const FuncU = preload("res://globals/FuncU.gd")

#var world_dir: String
var server_ip = null
var server_port = null
#var CONFIG_FILENAME: String
#var LEVEL_FILENAME: String

var enet = ENetMultiplayerPeer.new()
var smapi = SceneMultiplayer.new()
var crypto = Crypto.new()
var tickets = {}
signal finished_loading
var peer_users = {}


func _ready():
	print("starting server on %s:%d ..." % [server_ip, server_port])
	
	enet.set_bind_ip(server_ip)
	enet.create_server(server_port)
	smapi.multiplayer_peer = enet
	smapi.set_auth_callback(func(p, raw_data: PackedByteArray):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		if data.has("user_id"):
			var res = await $"/root/Main/Pocketbase".api_POST("myapp/create_server_ticket", { "user_id": data.user_id })
			if res.response_code != 200: print_debug("couldnt create server ticket"); return
			tickets[res.body.ticked_id] = { "user_id": res.body.user_id, "username": res.body.username, "token": res.body.token, "date": Time.get_unix_time_from_system() }
			smapi.send_auth(p, res.body.ticked_id.to_utf8_buffer())
			return
		
		elif data.has("ticket_token") and data.has("ticket_id"):
			if crypto.constant_time_compare(data.ticket_token.to_utf8_buffer(), tickets[data.ticket_id].token.to_utf8_buffer()):
				peer_users[p] = { "user_id": tickets[data.ticket_id].user_id, "username": tickets[data.ticket_id].username }
				tickets.erase(data.ticket_id)
				smapi.complete_auth(p)
				print("ticket auth peer %d as %s" % [p, peer_users[p].username])
				return
			else:
				smapi.disconnect_peer(p)
				print_debug("ticket auth fail from peer %d (sus)" % p)
				return
		
		print_debug("unknown request from peer %d, KICKED" % p)
		smapi.disconnect_peer(p)
	)
	smapi.peer_connected.connect(func(peer_id): print("connected user %s, peer_id: %d" % [peer_users[peer_id].username, peer_id]))
	smapi.peer_authentication_failed.connect(func(peer_id):
		print("peer %d failed auth" % peer_id)
		peer_users.erase(peer_id)
	)
	smapi.peer_disconnected.connect(func(peer_id):
		print("disconnected client peer %d" % peer_id)
		peer_users.erase(peer_id)
	)
	get_tree().set_multiplayer(smapi, get_path())
	
	finished_loading.emit()
	print("starting server done.")


