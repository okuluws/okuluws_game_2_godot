# TODO: support web export (maybe learn WebRTC)

extends Window


# REQUIRED
var worlds
var world_dir_path
var ip
var port

@export var players: Node
@export var items: Node
@export var inventories: Node
@export var overworld: Node
var modules

@onready var main = worlds.main
signal world_saving
var smapi = SceneMultiplayer.new()
var tickets = {}
var peers = {}
var _crypto = Crypto.new()


func _on_tree_entered():
	modules = {
		"players": players,
		"items": items,
		"inventories": inventories,
		"overworld": overworld,
	}
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		match data.action:
			"create_ticket":
				var res = await main.pb.api_POST("myapp/create_server_ticket", { "user_id": data.user_id })
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


func _ready():
	print("starting server with bind=%s port=%d" % [ip, port])
	
	var enet = ENetMultiplayerPeer.new()
	enet.set_bind_ip(ip)
	enet.create_server(port)
	port = enet.host.get_local_port()
	smapi.multiplayer_peer = enet

#
#func create_ticket(user_id: String, username: String) -> Dictionary:
	## technically this can collide🤓 - it's 512 bits brotha
	#var ticket_id = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(64))
	#
	## maybe thats not secure enough...
	#var key = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(2048))
	#
	#tickets[ticket_id] = { "user_id": user_id, "username": username, "key": key, "created": Time.get_unix_time_from_system() }
	#return { "id": ticket_id, "key": key }


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		world_saving.emit()
		queue_free()
