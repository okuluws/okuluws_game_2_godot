extends Node


var config = {
	"entities": {
		"overworld": preload("res://overworld/overworld.tscn"),
		"player": preload("res://player/player.tscn"),
		"punch": preload("res://player/punch.tscn"),
		"squareenemy": preload("res://squareenemy/squareenemy.tscn"),
	}
}

var local_server_pid = []
var enet = ENetMultiplayerPeer.new()
var player_nodes = {}
@onready var EntitySpawner: MultiplayerSpawner = $"MultiplayerSpawner"
@onready var Level: Node2D = $"Level"
const WORLDS_FOLDER = "user://worlds"
var SAVEFILE_PATH = "user://world.cfg"
var WORLD_FOLDER = "user://worlds/idk"


func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		pass
	


func start_client(full_server_address: String):
	print("Starting Client...")
	var server_address = full_server_address.get_slice(":", 0)
	var server_port = int(full_server_address.get_slice(":", 1))
	enet.create_client(server_address, server_port)
	multiplayer.multiplayer_peer = enet
	
	multiplayer.connected_to_server.connect(func(): print("connected to server peer"))
	


func start_server(full_server_address: String):
	print("Starting Server...")
	var _server_address = full_server_address.get_slice(":", 0)
	var server_port = int(full_server_address.get_slice(":", 1))
	enet.create_server(server_port)
	multiplayer.multiplayer_peer = enet
	
	multiplayer.peer_connected.connect(func(peer_id):
		print("connected client peer %d" % peer_id)
		
		var new_player_node = EntitySpawner.spawn({ "id": "player", "properties": { "name": str(peer_id), "player_type": "square" } })
		assign_player.rpc_id(peer_id, str(peer_id))
		player_nodes[peer_id] = new_player_node
	)
	
	multiplayer.peer_disconnected.connect(func(peer_id):
		print("disconnected client peer %d" % peer_id)
		player_nodes[peer_id].queue_free()
		player_nodes.erase(peer_id)
	)
	
	if FileAccess.file_exists(SAVEFILE_PATH):
		load_level()
	else:
		# initial world
		EntitySpawner.spawn({ "id": "overworld" })
		EntitySpawner.spawn({
			"id": "squareenemy",
			"properties": {
				"position": Vector2(randi_range(300, 800), randi_range(300, 800))
			},
		})
		
	save_level()


func start_local():
	# NOTE: delete before release
	var pid: int
	if OS.is_debug_build():
		pid = OS.create_process(OS.get_executable_path(), ["--server='127.0.0.1:42000'"], true)
	else:
		pid = OS.create_instance(["--headless", "--server='127.0.0.1:42000'"])
	#var pid = OS.create_instance(["--headless", "--server='127.0.0.1:42000'"])
	
	local_server_pid = [pid]
	start_client("127.0.0.1:42000")
	


@rpc
func assign_player(node_name: String):
	await get_tree().create_timer(0.1).timeout
	Level.get_node(node_name).add_child(Camera2D.new())
	


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_level()
		for pid in local_server_pid:
			OS.kill(pid)
	



## Creates new empty file if doesnt exist, else clears it, should proly make backup of the file :o
func save_level():
	var savefile = ConfigFile.new()
	savefile.save(SAVEFILE_PATH)
	for node in get_tree().get_nodes_in_group("Persist"):
		var pers_cfg = node.get_persistent()
		savefile.set_value(Level.get_path_to(node), "handler", pers_cfg.handler)
		savefile.set_value(Level.get_path_to(node), "data", pers_cfg.data)
	savefile.save(SAVEFILE_PATH)



## Can only load handlers in PRELOADED
func load_level():
	var savefile = ConfigFile.new()
	savefile.load(SAVEFILE_PATH)
	for section_key in savefile.get_sections():
		load(savefile.get_value(section_key, "handler")).new().load_persistent(savefile.get_value(section_key, "data"), self)
	

