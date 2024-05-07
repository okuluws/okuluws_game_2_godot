extends Node


var config = {
	"entities": {
		"overworld": preload("res://overworld/overworld.tscn"),
		"player": preload("res://player/player.tscn"),
		"punch": preload("res://player/punch.tscn"),
		"squareenemy": preload("res://squareenemy/squareenemy.tscn"),
	},
	"items": {
		"square_fragment": {
			"display_name": "Square Fragment",
			"texture": preload("res://player/square/square_fragment.png"),
			"slot_size": 1,
		},
		"widesquare_fragment": {
			"display_name": "Widesquare Fragment",
			"texture": preload("res://player/widesquare/widesquare_fragment.png"),
			"slot_size": 1,
		},
		"triangle_fragment": {
			"display_name": "Triangle Fragment",
			"texture": preload("res://player/triangle/triangle_fragment.png"),
			"slot_size": 1,
		},
	}
}

const FuncU = preload("res://globals/FuncU.gd")
@onready var Main: Node = $"/root/Main"
@onready var GUIs: CanvasLayer = Main.GUIs
@onready var EntitySpawner: MultiplayerSpawner = $"MultiplayerSpawner"
@onready var Level: Node2D = $"Level"
var WORLD_FOLDER: String
var enet = ENetMultiplayerPeer.new()
var smapi = SceneMultiplayer.new()
var player_nodes = {}



func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		$"In World Options".visible = not $"In World Options".visible
	


func start_client(full_server_address: String):
	print("Starting Client...")
	var server_address = full_server_address.get_slice(":", 0)
	var server_port = int(full_server_address.get_slice(":", 1))
	enet.create_client(server_address, server_port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
	multiplayer.connected_to_server.connect(func(): print("connected to server peer"))
	


## world_folder should be an absolute path
## server_address must contain port
func start_server(world_folder: String, full_server_address: String):
	print("Starting Server...")
	
	var cam = Camera2D.new()
	cam.zoom = Vector2.ONE * 0.2
	add_child(cam)
	
	if not DirAccess.dir_exists_absolute(world_folder): print("couldn't find folder >%s<" % world_folder); return
	WORLD_FOLDER = world_folder
	
	var _server_address = full_server_address.get_slice(":", 0)
	var server_port = int(full_server_address.get_slice(":", 1))
	enet.create_server(server_port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
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
	
	if FileAccess.file_exists("%s/level.cfg" % WORLD_FOLDER):
		load_level()
	else:
		# initial world
		EntitySpawner.spawn({ "id": "overworld" })
		EntitySpawner.spawn({
			"id": "squareenemy",
			"properties": {
				"position": Vector2(randi_range(100, 400), randi_range(100, 400))
			},
		})
	
	save_level()


@rpc
func assign_player(node_name: String):
	await get_tree().create_timer(0.1).timeout
	Level.get_node(node_name).add_child(Camera2D.new())
	


## Creates new empty file if doesnt exist, else clears it, should proly make backup of the file :o
func save_level():
	var savefile = FuncU.BetterConfigFile.new("%s/level.cfg" % WORLD_FOLDER)
	for node in get_tree().get_nodes_in_group("Persist"):
		var pers_cfg = node.get_persistent()
		savefile.set_value(Level.get_path_to(node), "handler", pers_cfg.handler)
		savefile.set_value(Level.get_path_to(node), "data", pers_cfg.data)
	savefile.save()


func load_level():
	var savefile = ConfigFile.new()
	savefile.load("%s/level.cfg" % WORLD_FOLDER)
	for section_key in savefile.get_sections():
		load(savefile.get_value(section_key, "handler")).new().load_persistent(savefile.get_value(section_key, "data"), self)
	

static func create_world_folder(world_name: String) -> String:
	var world_name_converted = world_name.replace(" ", "_")
	var worlds_dir = DirAccess.open("user://worlds")
	if DirAccess.dir_exists_absolute(world_name_converted): print("folder >%s< already exists" % world_name_converted); return ""
	worlds_dir.make_dir(world_name_converted)
	var world_dir = DirAccess.open("%s/%s" % [worlds_dir.get_current_dir(), world_name_converted])
	var world_config = FuncU.BetterConfigFile.new("%s/config.cfg" % world_dir.get_current_dir())
	
	world_config.set_base_value("name", world_name)
	world_config.set_base_value("playtime", 0.0)
	world_config.set_base_value("version", "0.0.1")
	world_config.save()
	
	return world_dir.get_current_dir()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_level()





func _on_quit_pressed():
	GUIs.add_child(preload("res://gui/home.tscn").instantiate())
	queue_free()
