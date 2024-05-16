extends SubViewport


var server_ip: String
var server_port: int

var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()
var token = ""



func _ready():
	print("starting client...")
	
	
	if $"/root/Main/Worlds".servers.has("%s:%d" % [server_ip, server_port]):
		smapi.peer_authenticating.connect(func(_peer):
			smapi.send_auth(1, [0])
			smapi.complete_auth(1)
		)
	else:
		var res = await $"/root/Main/Pocketbase".api_POST("myapp/server_join", { "server_address": "%s:%d" % [server_ip, server_port] }, true)
		if res.response_code != 200:
			printerr("couldnt request server_join")
			return
		token = res.body.token
		
		smapi.peer_authenticating.connect(func(_peer):
			smapi.send_auth(1, JSON.stringify({ "token": token, "user_id": $"/root/Main/Pocketbase".user_id }).to_ascii_buffer())
			smapi.complete_auth(1)
		)
	
	enet.create_client(server_ip, server_port)
	smapi.multiplayer_peer = enet
	smapi.set_auth_callback(func(_peer): pass)
	smapi.connected_to_server.connect(func(): print("connected to server peer"))
	smapi.server_disconnected.connect(func(): print("disconnected from server peer"))
	get_tree().set_multiplayer(smapi, get_path())
	
	
	print("starting client done.")
	



