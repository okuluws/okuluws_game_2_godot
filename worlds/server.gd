extends SubViewport


const FuncU = preload("res://globals/FuncU.gd")

var world_dir: String
var port: int
var CONFIG_FILENAME: String
var LEVEL_FILENAME: String
var MODS_FILENAME: String

var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()
signal finished_loading


func _ready():
	print("starting server...")
	
	var mods_cfg = FuncU.BetterConfigFile.new("%s/%s" % [world_dir, MODS_FILENAME])
	mods_cfg.set_value("server", "Overworld", "res://overworld/main.tscn")
	mods_cfg.set_value("client", "Overworld", "res://overworld/main.tscn")
	mods_cfg.save()
	
	var mods_node = Node.new()
	mods_node.name = "Mods"
	
	print("loading server mods ...")
	for mod_name in mods_cfg.get_section_keys("server"):
		prints("loading", mod_name, "at", mods_cfg.get_value("server", mod_name))
		var node = load(mods_cfg.get_value("server", mod_name)).instantiate()
		node.name = mod_name
		mods_node.add_child(node)
	add_child(mods_node)
	print("loading server mods done.")
	
	
	enet.create_server(port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(func(peer_id: int): print("disconnected client peer %d" % peer_id))
	
	
	finished_loading.emit()
	

func _on_peer_connected(peer_id: int):
	print("connected client peer %d" % peer_id)
	var mods_cfg = FuncU.BetterConfigFile.new("%s/%s" % [world_dir, MODS_FILENAME])
	load_mods_config.bind(mods_cfg.to_text()).rpc_id(peer_id)

@rpc func load_mods_config(_cfg_text: String): pass

@rpc("any_peer") func peer_finished_loading_mods():
	prints("ok", multiplayer.get_remote_sender_id())

