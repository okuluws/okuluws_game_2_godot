extends SubViewport


var server_address: String

var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()


func _ready():
	print("starting client...")
	
	enet.create_client(server_address.get_slice(":", 0), int(server_address.get_slice(":", 1)))
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
	multiplayer.connected_to_server.connect(func(): print("connected to server peer"))
	multiplayer.server_disconnected.connect(func(): print("disconnected from server peer"))
	


