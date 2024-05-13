extends SubViewport


const FuncU = preload("res://globals/FuncU.gd")

var world_dir: String
var port: int
var CONFIG_FILENAME: String
var LEVEL_FILENAME: String

var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()
var tcp_api = TCPServer.new()
signal finished_loading


func _ready():
	print("starting server...")
	
	enet.create_server(port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(func(peer_id: int): print("disconnected client peer %d" % peer_id))
	
	
	finished_loading.emit()
	

func _on_peer_connected(peer_id: int):
	print("connected client peer %d" % peer_id)
	

