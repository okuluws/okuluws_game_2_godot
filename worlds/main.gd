extends Node


# REQUIRED
@export var main: Node

@export var client_world_scene: PackedScene
@export var server_world_scene: PackedScene
var worlds_dir_path = "user://worlds"
var clients = []
var servers = []


func _ready():
	if not DirAccess.dir_exists_absolute(worlds_dir_path): DirAccess.make_dir_absolute(worlds_dir_path)


func create_world_folder(world_dir_path, world_name):
	var worlds_dir = DirAccess.open(worlds_dir_path)
	if worlds_dir.dir_exists(world_dir_path): print_debug("world folder >%s< already exists" % world_dir_path); return
	worlds_dir.make_dir(world_dir_path)
	var world_config = ConfigFile.new()
	world_config.set_value("", "name", world_name)
	world_config.set_value("", "playtime", 0.0)
	world_config.set_value("", "version", ProjectSettings.get_setting_with_override("application/config/version"))
	if world_config.save(world_dir_path.path_join("config.cfg")) != OK: push_error(); return


func make_client(server_address: String) -> Node:
	var client = _setup_client(server_address)
	$"SubViewportContainer".add_child(client)
	clients.append(client)
	return client


func _setup_client(server_address: String) -> Node:
	var client = client_world_scene.instantiate()
	client.main = main
	var a = _parse_server_address(server_address)
	client.server_ip = a.ip
	client.server_port = a.port
	return client


func make_server(world_dir_path: String, server_address: String) -> Node:
	var server = _setup_server(world_dir_path, server_address)
	add_child(server)
	servers.append(server)
	return server


func _setup_server(world_dir_path: String, server_address: String) -> Node:
	var server = server_world_scene.instantiate()
	server.main = main
	var a = _parse_server_address(server_address)
	server.world_dir_path = world_dir_path
	server.server_ip = a.ip
	server.server_port = a.port
	return server


func make_singleplayer(world_dir_path: String) -> Dictionary:
	var offline_token = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(2048))
	
	var server = _setup_server(world_dir_path, "127.0.0.1:42000")
	server.tickets["-1"] = { "user_id": "-1", "username": "local player", "token": offline_token, "date": Time.get_unix_time_from_system() }
	add_child(server)
	servers.append(server)
	
	var client = _setup_client("127.0.0.1:42000")
	client.ticket_id = "-1"
	client.ticket_token = offline_token
	client.quit_world_queued.connect(server.shutdown)
	add_child(client)
	clients.append(client)
	
	return { "server": server, "client": client }


# TODO: Support shortened / shortcut ip addresses like 0.0.0.0 or ::1
func _parse_server_address(s: String):
	var port_str = s.split(":")[-1]
	return { "ip": s.trim_suffix(":%s" % port_str).lstrip("[").rstrip("]"), "port": int(port_str) }




