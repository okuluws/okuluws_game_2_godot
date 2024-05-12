extends Node


const FuncU = preload("res://globals/FuncU.gd")
const WORLDS_DIR = "user://worlds"
const WORLD_CONFIG_FILENAME = "config.cfg"
const WORLD_LEVEL_FILENAME = "level.cfg"
const WORLD_MODS_FILENAME = "mods.cfg"
const CLIENT_MODS_FILENAME = "remote_worlds.cfg"


func _ready():
	if not DirAccess.dir_exists_absolute(WORLDS_DIR):
		DirAccess.make_dir_absolute(WORLDS_DIR)
	

func create_world_folder(world_name: String) -> int:
	var worlds_dir = DirAccess.open(WORLDS_DIR)
	if worlds_dir.dir_exists(world_name): printerr("world folder >%s< already exists" % world_name); return FAILED
	worlds_dir.make_dir(world_name)
	var world_dir = DirAccess.open("%s/%s" % [worlds_dir.get_current_dir(), world_name])
	
	var world_config = FuncU.BetterConfigFile.new("%s/%s" % [world_dir.get_current_dir(), WORLD_CONFIG_FILENAME])
	world_config.set_base_value("name", world_name)
	world_config.set_base_value("playtime", 0.0)
	world_config.set_base_value("version", "0.0.1")
	world_config.save()
	
	FileAccess.open("%s/%s" % [world_dir.get_current_dir(), WORLD_MODS_FILENAME], FileAccess.WRITE)
	
	return OK


func make_client(server_address: String) -> Node:
	var client = preload("res://worlds/client.tscn").instantiate()
	client.server_address = server_address
	$"SubViewportContainer".add_child(client)
	return client


func make_server(world_dir: String, port: int = 42000) -> Node:
	var server = preload("res://worlds/server.tscn").instantiate()
	server.world_dir = world_dir
	server.port = port
	server.CONFIG_FILENAME = WORLD_CONFIG_FILENAME
	server.LEVEL_FILENAME = WORLD_LEVEL_FILENAME
	server.MODS_FILENAME = WORLD_MODS_FILENAME
	add_child(server)
	return server


func make_server_and_client(world_dir: String, port: int = 42000) -> Dictionary:
	return { "server": make_server(world_dir, port), "client": make_client("127.0.0.1:%d" % port) }
