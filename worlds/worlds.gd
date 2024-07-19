extends Node


const GameMain = preload("res://main.gd")
const src_dirpath = "res://worlds/"
const Server = preload(src_dirpath + "server.gd")
const Client = preload(src_dirpath + "client.gd")
const configs_dirpath = "user://worlds/"
const servers_config_filepath = configs_dirpath + "servers.cfg"
const clients_config_filepath = configs_dirpath + "clients.cfg"
const default_server_config_path = src_dirpath + "default_server_config.cfg"
const default_client_config_path = src_dirpath + "default_client_config.cfg"
# why the fuck is there no text ressource - 28.06.2024
@export var scene_server_world: PackedScene
@export var scene_client_world: PackedScene
var game_main: GameMain
var default_server_config = ConfigFile.new()
var default_client_config = ConfigFile.new()
var servers_config = ConfigFile.new()
var clients_config = ConfigFile.new()
var active_servers = {}
var active_clients = {}


func init(p_game_main: GameMain) -> void:
	game_main = p_game_main
	var err = game_main.func_u.ConfigFile_load(default_server_config, default_server_config_path)
	if err != null: game_main.func_u.unreachable(err)
	err = game_main.func_u.ConfigFile_load(default_client_config, default_client_config_path)
	if err != null: game_main.func_u.unreachable(err)
	
	if not DirAccess.dir_exists_absolute(configs_dirpath):
		err = game_main.func_u.DirAccess_make_dir_absolute(configs_dirpath)
		if err != null: game_main.func_u.unreachable(err)
	
	if not FileAccess.file_exists(servers_config_filepath):
		err = _save_servers_config()
		if err != null: game_main.func_u.unreachable(err)
	else:
		err = game_main.func_u.ConfigFile_load(servers_config, servers_config_filepath)
		if err != null: game_main.func_u.unreachable(err)
	
	if not FileAccess.file_exists(clients_config_filepath):
		err = _save_servers_config()
		if err != null: game_main.func_u.unreachable(err)
	else:
		err = game_main.func_u.ConfigFile_load(clients_config, clients_config_filepath)
		if err != null: game_main.func_u.unreachable(err)


func _exit_tree() -> void:
	_save_servers_config()
	_save_clients_config()


func create_server_world(display_name: String) -> Dictionary:
	var new_world_dir_path = configs_dirpath.path_join("server_" + display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system()))
	var err = game_main.func_u.DirAccess_make_dir_absolute(new_world_dir_path)
	if err != null: return { "err": err, "ret": null }
	
	servers_config.set_value(new_world_dir_path, "hidden", false)
	
	err = _save_servers_config()
	if err != null: return { "err": err, "ret": null }
	
	var new_world_config = ConfigFile.new()
	err = game_main.func_u.ConfigFile_copy(new_world_config, default_server_config)
	if err != null: return { "err": err, "ret": null }
	
	new_world_config.set_value("general", "name", display_name)
	
	err = game_main.func_u.ConfigFile_save(new_world_config, new_world_dir_path.path_join("world.cfg"))
	if err != null: return { "err": err, "ret": null }
	
	return { "err": null, "ret": new_world_dir_path }


func create_client_world(display_name: String, options: Dictionary) -> Dictionary:
	var new_world_dir_path = configs_dirpath.path_join("client_" + display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system()))
	var err = game_main.func_u.DirAccess_make_dir_absolute(new_world_dir_path)
	if err != null: return { "err": err, "ret": null }
	
	clients_config.set_value(new_world_dir_path, "hidden", options.has("server_world_dir_path"))
	
	err = _save_clients_config()
	if err != null: return { "err": err, "ret": null }
	
	var new_world_config = ConfigFile.new()
	err = game_main.func_u.ConfigFile_copy(new_world_config, default_client_config)
	if err != null: return { "err": err, "ret": null }
	
	new_world_config.set_value("general", "name", display_name)
	if options.has("server_world_dir_path"):
		new_world_config.set_value("general", "server_world_dir_path", options.server_world_dir_path)
	else:
		new_world_config.set_value("general", "server_ip", options.ip)
		new_world_config.set_value("general", "server_port", options.port)
	
	err = game_main.func_u.ConfigFile_save(new_world_config, new_world_dir_path.path_join("world.cfg"))
	if err != null: return { "err": err, "ret": null }
	
	return { "err": null, "ret": new_world_dir_path }


func delete_server_world(path: String):
	game_main.func_u.delete_recursively(path)
	return unlink_server_world(path)


func delete_client_world(path: String):
	game_main.func_u.delete_recursively(path)
	return unlink_client_world(path)


func unlink_server_world(path: String):
	servers_config.erase_section(path)
	return _save_servers_config()


func unlink_client_world(path: String):
	clients_config.erase_section(path)
	return _save_clients_config()


func _save_servers_config():
	return game_main.func_u.ConfigFile_save(servers_config, servers_config_filepath)


func _save_clients_config():
	return game_main.func_u.ConfigFile_save(clients_config, clients_config_filepath)


func start_server(world_dir_path: String):
	var new_server: Server = scene_server_world.instantiate()
	new_server.worlds = self
	new_server.world_dir_path = world_dir_path
	add_child(new_server)
	active_servers[new_server] = {}
	new_server.tree_exited.connect(func():
		active_servers.erase(new_server)
	)
	return new_server


func start_client(world_dir_path: String):
	var new_client: Client = scene_client_world.instantiate()
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
