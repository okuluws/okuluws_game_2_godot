# TODO: Support shortened / shortcut ip addresses like 0.0.0.0 or ::1

extends Node


const WORLDS_DIR = "user://worlds"
var client_world_scene = load("res://worlds/client.tscn")
var server_world_scene = load("res://worlds/server.tscn")

var clients = []
var servers = []


func _ready():
	if not DirAccess.dir_exists_absolute(WORLDS_DIR): DirAccess.make_dir_absolute(WORLDS_DIR)
	


func create_world_folder(path, world_name):
	var worlds_dir = DirAccess.open(WORLDS_DIR)
	if worlds_dir.dir_exists(path): print_debug("world folder >%s< already exists" % path); return
	worlds_dir.make_dir(path)
	var world_config = ConfigFile.new()
	world_config.set_value("", "name", world_name)
	world_config.set_value("", "playtime", 0.0)
	world_config.set_value("", "version", ProjectSettings.get_setting_with_override("application/config/version"))
	if world_config.save(path.path_join("config.cfg")) != OK: push_error(); return
	


func make_client(server_address: String) -> Node:
	var client = _setup_client(server_address)
	$"SubViewportContainer".add_child(client)
	clients.append(client)
	return client


func _setup_client(server_address: String) -> Node:
	var client = client_world_scene.instantiate()
	var a = _parse_server_address(server_address)
	client.server_ip = a.ip
	client.server_port = a.port
	return client


func make_server(world_dir: String, server_address: String) -> Node:
	var server = _setup_server(world_dir, server_address)
	add_child(server)
	servers.append(server)
	return server

func _setup_server(world_dir: String, server_address: String) -> Node:
	var server = server_world_scene.instantiate()
	var a = _parse_server_address(server_address)
	server.world_dir = world_dir
	server.server_ip = a.ip
	server.server_port = a.port
	return server


func make_singleplayer(world_dir: String) -> Dictionary:
	var offline_token = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(2048))
	
	var server = _setup_server(world_dir, "127.0.0.1:42000")
	server.tickets["-1"] = { "user_id": "-1", "username": "local player", "token": offline_token, "date": Time.get_unix_time_from_system() }
	add_child(server)
	servers.append(server)
	
	var client = _setup_client("127.0.0.1:42000")
	client.ticket_id = "-1"
	client.ticket_token = offline_token
	client.quit_world_queued.connect(server.shutdown)
	$"SubViewportContainer".add_child(client)
	clients.append(client)
	
	return { "server": server, "client": client }


func _parse_server_address(s: String):
	var port_str = s.split(":")[-1]
	return { "ip": s.trim_suffix(":%s" % port_str).lstrip("[").rstrip("]"), "port": int(port_str) }




