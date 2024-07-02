extends Node


# REQUIRED
@export var main: Node

@export var scene_server_world: PackedScene
@export var scene_client_world: PackedScene
# why the fuck is there no text ressource - 28.06.2024
@export_file var default_server_config_path
@export_file var default_client_config_path
@onready var func_u = main.modules.func_u
var default_server_config = ConfigFile.new()
var default_client_config = ConfigFile.new()
var worlds_dir_path = "user://worlds"
var servers_config = ConfigFile.new()
var servers_config_file_path = worlds_dir_path.path_join("server_worlds.cfg")
var clients_config = ConfigFile.new()
var clients_config_file_path = worlds_dir_path.path_join("client_worlds.cfg")
var active_servers = {}
var active_clients = {}


func _ready():
	var err
	
	err = func_u.ConfigFile_load(default_server_config, default_server_config_path)
	if err != null: func_u.unreachable(err)
	err = func_u.ConfigFile_load(default_client_config, default_client_config_path)
	if err != null: func_u.unreachable(err)
	
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


func create_server_world(display_name: String):
	var err
	var new_world_dir_path = worlds_dir_path.path_join("server_" + display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system()))
	err = func_u.DirAccess_make_dir_absolute(new_world_dir_path)
	if err != null: return { "err": err, "ret": null }
	
	servers_config.set_value(new_world_dir_path, "hidden", false)
	
	err = _save_servers_config()
	if err != null: return { "err": err, "ret": null }
	
	var new_world_config = ConfigFile.new()
	err = func_u.ConfigFile_copy(new_world_config, default_server_config)
	if err != null: return { "err": err, "ret": null }
	
	new_world_config.set_value("general", "name", display_name)
	
	err = func_u.ConfigFile_save(new_world_config, new_world_dir_path.path_join("world.cfg"))
	if err != null: return { "err": err, "ret": null }
	
	return { "err": null, "ret": new_world_dir_path }


func create_client_world(display_name: String, ip: String, port: int):
	var err
	var new_world_dir_path = worlds_dir_path.path_join("client_" + display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system()))
	err = func_u.DirAccess_make_dir_absolute(new_world_dir_path)
	if err != null: return { "err": err, "ret": null }
	
	clients_config.set_value(new_world_dir_path, "hidden", false)
	
	err = _save_clients_config()
	if err != null: return { "err": err, "ret": null }
	
	var new_world_config = ConfigFile.new()
	err = func_u.ConfigFile_copy(new_world_config, default_client_config)
	if err != null: return { "err": err, "ret": null }
	
	new_world_config.set_value("general", "name", display_name)
	new_world_config.set_value("general", "server_ip", ip)
	new_world_config.set_value("general", "server_port", port)
	
	err = func_u.ConfigFile_save(new_world_config, new_world_dir_path.path_join("world.cfg"))
	if err != null: return { "err": err, "ret": null }
	
	return { "err": null, "ret": new_world_dir_path }


func delete_server_world(path: String):
	func_u.delete_recursively(path)
	return unlink_server_world(path)


func delete_client_world(path: String):
	func_u.delete_recursively(path)
	return unlink_client_world(path)


func unlink_server_world(path: String):
	servers_config.erase_section(path)
	return _save_servers_config()


func unlink_client_world(path: String):
	clients_config.erase_section(path)
	return _save_clients_config()


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


func start_client(world_dir_path: String):
	var new_client = scene_client_world.instantiate()
	new_client.worlds = self
	new_client.world_dir_path = world_dir_path
	add_child(new_client)
	active_clients[new_client] = {}
	new_client.tree_exited.connect(func():
		active_clients.erase(new_client)
	)
	return new_client


#func start_client_local(server_node: Node):
	#var new_client = scene_client_world.instantiate()
	#new_client.worlds = self
	#new_client.server_node = server_node
	#add_child(new_client)
	#active_clients[new_client] = {}
	#new_client.tree_exited.connect(func():
		#active_clients.erase(new_client)
	#)
	#return new_client
