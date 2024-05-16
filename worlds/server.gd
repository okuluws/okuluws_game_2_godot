extends SubViewport


const FuncU = preload("res://globals/FuncU.gd")

#var world_dir: String
var server_ip: String
var server_port: int
#var CONFIG_FILENAME: String
#var LEVEL_FILENAME: String

var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()

signal finished_loading


func _ready():
	print("starting server...")
	
	enet.set_bind_ip(server_ip)
	enet.create_server(server_port)
	smapi.multiplayer_peer = enet
	smapi.set_auth_callback(func(peer, raw_data: PackedByteArray):
		var my_addr = "%s:%d" % [server_ip, server_port]
		if $"/root/Main/Worlds".clients.has(my_addr) and $"/root/Main/Worlds".clients[my_addr].any(func(c): return c.multiplayer.get_unique_id() == peer):
			smapi.complete_auth(peer)
			return
		
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		var res = await $"/root/Main/Pocketbase".api_POST("myapp/server_client_validate", { "user_id": data.user_id, "token": data.token })
		if res.response_code == 200:
			smapi.complete_auth(peer)
		else:
			smapi.disconnect_peer(peer)
	)
	smapi.peer_connected.connect(func(peer_id): print("connected client peer %d" % peer_id))
	smapi.peer_disconnected.connect(func(peer_id): print("disconnected client peer %d" % peer_id))
	get_tree().set_multiplayer(smapi, get_path())
	
	finished_loading.emit()
	print("starting server done.")

