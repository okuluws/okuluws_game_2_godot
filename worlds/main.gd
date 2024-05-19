# TODO: Support shortened / shortcut ip addresses like 0.0.0.0 or ::1

extends Node


const FuncU = preload("res://globals/FuncU.gd")
const WORLDS_DIR = "user://worlds"
const WORLD_CONFIG_FILENAME = "config.cfg"
const WORLD_LEVEL_FILENAME = "level.cfg"
const client_world_file = "res://worlds/client.tscn"
const server_world_file = "res://worlds/server.tscn"

var clients = []
var servers = []


func _ready():
	if not DirAccess.dir_exists_absolute(WORLDS_DIR):
		DirAccess.make_dir_absolute(WORLDS_DIR)
	

func create_world_folder(world_name: String) -> int:
	var worlds_dir = DirAccess.open(WORLDS_DIR)
	if worlds_dir.dir_exists(world_name): print_debug("world folder >%s< already exists" % world_name); return FAILED
	worlds_dir.make_dir(world_name)
	var world_dir = DirAccess.open("%s/%s" % [worlds_dir.get_current_dir(), world_name])
	
	var world_config = FuncU.BetterConfigFile.new("%s/%s" % [world_dir.get_current_dir(), WORLD_CONFIG_FILENAME])
	world_config.set_base_value("name", world_name)
	world_config.set_base_value("playtime", 0.0)
	world_config.set_base_value("version", "0.0.1")
	world_config.save()
	
	return OK


func make_client(server_address: String) -> Node:
	var client = _setup_client_w_addr(server_address)
	$"SubViewportContainer".add_child(client)
	clients.append(client)
	return client


func _setup_client_w_addr(server_address: String) -> Node:
	var client = load(client_world_file).instantiate()
	var a = _parse_server_address(server_address)
	client.server_ip = a.ip
	client.server_port = a.port
	return client


func make_server(_world_dir: String, server_address: String) -> Node:
	var server = load(server_world_file).instantiate()
	#server.world_dir = world_dir
	var a = _parse_server_address(server_address)
	server.server_ip = a.ip
	server.server_port = a.port
	#server.CONFIG_FILENAME = WORLD_CONFIG_FILENAME
	#server.LEVEL_FILENAME = WORLD_LEVEL_FILENAME
	add_child(server)
	servers.append(server)
	return server


func make_singleplayer(world_dir: String) -> Dictionary:
	var offline_token = Marshalls.raw_to_base64(Crypto.new().generate_random_bytes(2048))
	var server = make_server(world_dir, "127.0.0.1:42000")
	server.tickets["-1"] = { "user_id": $"/root/Main/Pocketbase".user_id, "username": $"/root/Main/Pocketbase".username, "token": offline_token, "date": Time.get_unix_time_from_system() }
	var client = _setup_client_w_addr("127.0.0.1:42000")
	client.ticket_id = "-1"
	client.ticket_token = offline_token
	$"SubViewportContainer".add_child(client)
	clients.append(client)
	return { "server": server, "client": client }


func _parse_server_address(s: String):
	var port_str = s.split(":")[-1]
	return { "ip": s.trim_suffix(":%s" % port_str).lstrip("[").rstrip("]"), "port": int(port_str) }




