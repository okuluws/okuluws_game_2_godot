extends Node


# REQUIRED
@export var main: Node

@export var scene_server_world: PackedScene
@export var scene_client_world: PackedScene
@onready var func_u = main.modules.func_u
var worlds_dir_path = "user://worlds"
var servers_config = ConfigFile.new()
var servers_config_file_path = worlds_dir_path.path_join("server_worlds.cfg")
var clients_config = ConfigFile.new()
var clients_config_file_path = worlds_dir_path.path_join("client_worlds.cfg")
var active_servers = {}
var active_clients = {}


func _ready():
	var err
	if not DirAccess.dir_exists_absolute(worlds_dir_path):
		err = func_u.DirAccess_make_dir_absolute(worlds_dir_path)
		if err != null: func_u.unreachable(err)
	
	if not FileAccess.file_exists(servers_config_file_path):
		err = _save_servers_config()
		if err != null: func_u.unreachable(err)
	else:
		err = func_u.ConfigFile_load(servers_config, servers_config_file_path)
		if err != null: func_u.unreachable(err)
	
	if not FileAccess.file_exists(clients_config_file_path):
		err = _save_servers_config()
		if err != null: func_u.unreachable(err)
	else:
		err = func_u.ConfigFile_load(clients_config, clients_config_file_path)
		if err != null: func_u.unreachable(err)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_servers_config()
		_save_clients_config()


func create_world(display_name: String):
	var err
	var new_world_dir_path = worlds_dir_path.path_join(display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system()))
	err = func_u.DirAccess_make_dir_absolute(new_world_dir_path)
	if err != null:
		return { "err": err, "ret": null }
	
	servers_config.set_value(new_world_dir_path, "hidden", false)
	
	err = _save_servers_config()
	if err != null:
		return { "err": err, "ret": null }
	
	var new_world_config = ConfigFile.new()
	new_world_config.set_value("general", "name", display_name)
	new_world_config.set_value("network", "bind_ip", "127.0.0.1")
	new_world_config.set_value("network", "port", 20070)
	err = func_u.ConfigFile_save(new_world_config, new_world_dir_path.path_join("world.cfg"))
	if err != null:
		return { "err": err, "ret": null }
	
	return { "err": null, "ret": new_world_dir_path }


func add_client_config(display_name: String, ip: String, port: int):
	var client_id = display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system())
	
	clients_config.set_value(client_id, "general/name", display_name)
	clients_config.set_value(client_id, "network/server_ip", ip)
	clients_config.set_value(client_id, "network/server_port", port)
	
	var err = _save_clients_config()
	if err != null:
		return { "err": err, "ret": null }
	
	return { "err": null, "ret": client_id }


func remove_client_config(id: String):
	clients_config.erase_section(id)
	return _save_clients_config()


func unlink_world(path: String):
	servers_config.erase_section(path)
	return _save_servers_config()


func delete_world(path: String):
	func_u.delete_recursively(path)
	return unlink_world(path)


func _save_servers_config():
	return func_u.ConfigFile_save(servers_config, servers_config_file_path)


func _save_clients_config():
	return func_u.ConfigFile_save(clients_config, clients_config_file_path)


func start_server(world_dir_path: String):
	var new_server = scene_server_world.instantiate()
	new_server.worlds = self
	new_server.world_dir_path = world_dir_path
	add_child(new_server)
	active_servers[new_server] = {}
	new_server.tree_exited.connect(func():
		active_servers.erase(new_server)
	)
	return new_server


func start_client(id: String):
	var new_client = scene_client_world.instantiate()
	new_client.worlds = self
	new_client.server_ip = clients_config.get_value(id, "network/server_ip")
	new_client.server_port = clients_config.get_value(id, "network/server_port")
	add_child(new_client)
	active_clients[new_client] = {}
	new_client.tree_exited.connect(func():
		active_clients.erase(new_client)
	)
	return new_client


func start_client_local(server_node: Node):
	var new_client = scene_client_world.instantiate()
	new_client.worlds = self
	new_client.server_node = server_node
	add_child(new_client)
	active_clients[new_client] = {}
	new_client.tree_exited.connect(func():
		active_clients.erase(new_client)
	)
	return new_client
