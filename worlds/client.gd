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
	

@rpc func load_mods_config(cfg_text: String):
	var mods_cfg = ConfigFile.new()
	mods_cfg.parse(cfg_text)
	
	var mods_node = Node.new()
	mods_node.name = "Mods"
	
	print("loading client mods ...")
	for mod_name in mods_cfg.get_section_keys("client"):
		prints("loading", mod_name, "at", mods_cfg.get_value("client", mod_name))
		var node = load(mods_cfg.get_value("client", mod_name)).instantiate()
		node.name = mod_name
		mods_node.add_child(node)
	add_child(mods_node)
	print("loading client mods done.")
	
	peer_finished_loading_mods.rpc_id(1)
	

@rpc func peer_finished_loading_mods(): pass


