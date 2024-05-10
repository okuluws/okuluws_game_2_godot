extends Node


var config := {
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
const WORLDS_FOLDER = "user://worlds"
const WORLD_CONFIG_FILENAME = "config.cfg"
const home_scene = preload("res://home/home.tscn")
@onready var main: Main = $"/root/Main"
@onready var EntitySpawner: MultiplayerSpawner = $"MultiplayerSpawner"
@onready var Level: Node2D = $"Level"
@onready var in_world_options: CanvasLayer = $"In World Options"
var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()
var player_nodes := {}
var world_folder_name: String
var world_folder: String:
	get: return "%s/%s" % [WORLDS_FOLDER, world_folder_name]
	set(_val): printerr("property is readonly")

const LEVEL_FILENAME = "level.cfg"
var level_file: String:
	get: return "%s/%s" % [world_folder, LEVEL_FILENAME]
	set(_val): printerr("property is readonly")

var config_file: String:
	get: return "%s/%s" % [world_folder, WORLD_CONFIG_FILENAME]
	set(_val): printerr("property is readonly")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		in_world_options.visible = not in_world_options.visible
	


func start_client(full_server_address: String) -> void:
	print("Starting Client...")
	var server_address := full_server_address.get_slice(":", 0)
	var server_port := int(full_server_address.get_slice(":", 1))
	enet.create_client(server_address, server_port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
	multiplayer.connected_to_server.connect(func() -> void: print("connected to server peer"))
	multiplayer.server_disconnected.connect(func() -> void: print("disconnected from server peer"))
	


## world_folder should be an absolute path
func start_server(_world_folder_name: String, full_server_address: String) -> void:
	print("Starting Server...")
	
	world_folder_name = _world_folder_name
	var cam := Camera2D.new()
	cam.zoom = Vector2.ONE * 0.2
	add_child(cam)
	
	if not DirAccess.dir_exists_absolute(world_folder): printerr("couldn't find world folder >%s<" % world_folder); return
	
	var _server_address := full_server_address.get_slice(":", 0)
	var server_port := int(full_server_address.get_slice(":", 1))
	enet.create_server(server_port)
	smapi.multiplayer_peer = enet
	get_tree().set_multiplayer(smapi, get_path())
	
	multiplayer.peer_connected.connect(func(peer_id: int) -> void:
		print("connected client peer %d" % peer_id)
		
		var new_player_node := EntitySpawner.spawn({ "id": "player", "properties": { "name": str(peer_id), "player_type": "square" } })
		assign_player.rpc_id(peer_id, str(peer_id))
		player_nodes[peer_id] = new_player_node
	)
	
	multiplayer.peer_disconnected.connect(func(peer_id: int) -> void:
		print("disconnected client peer %d" % peer_id)
		(player_nodes.get(peer_id) as Node).queue_free()
		player_nodes.erase(peer_id)
	)
	
	if FileAccess.file_exists(level_file):
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
func assign_player(node_name: String) -> void:
	await get_tree().create_timer(0.1).timeout
	Level.get_node(node_name).add_child(Camera2D.new())
	


## deletes current save, should proly make backup :o
func save_level() -> void:
	if not multiplayer.is_server(): printerr("can't save level as client"); return
	print("Saving Level...")
	DirAccess.remove_absolute(level_file)
	var savefile := FuncU.BetterConfigFile.new(level_file)
	for node in Level.get_children():
		if not "PersistHandler" in node: continue
		savefile.set_value(Level.get_path_to(node), "handler", ((node.get("PersistHandler") as Node).get_script() as Script).get_path())
		savefile.set_value(Level.get_path_to(node), "data", (node.get("PersistHandler") as Node).call("get_persistent"))
	savefile.save()


func load_level() -> void:
	var savefile := ConfigFile.new()
	savefile.load(level_file)
	for section_key in savefile.get_sections():
		load(savefile.get_value(section_key, "handler") as String).call("load_persistent", (savefile.get_value(section_key, "data")), self)
	

static func create_world_folder(world_name: String) -> String:
	var world_name_converted := world_name.replace(" ", "_")
	var worlds_dir := DirAccess.open(WORLDS_FOLDER)
	if worlds_dir.dir_exists(world_name_converted): printerr("world folder >%s< already exists" % world_name_converted); return ""
	worlds_dir.make_dir(world_name_converted)
	var world_dir := DirAccess.open("%s/%s" % [worlds_dir.get_current_dir(), world_name_converted])
	var world_config := FuncU.BetterConfigFile.new("%s/%s" % [world_dir.get_current_dir(), WORLD_CONFIG_FILENAME])
	
	world_config.set_base_value("name", world_name)
	world_config.set_base_value("playtime", 0.0)
	world_config.set_base_value("version", "0.0.1")
	world_config.save()
	
	return world_dir.get_current_dir()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			save_level()





func _on_quit_pressed() -> void:
	main.GUIs.add_child(home_scene.instantiate())
	queue_free()
