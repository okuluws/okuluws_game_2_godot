extends Node


const GameMain = preload("res://main.gd")
const source_directory = "res://worlds/"
const Server = preload(source_directory + "server.gd")
const Client = preload(source_directory + "client.gd")
const configs_directory = "user://worlds/"
const servers_config_file = configs_directory + "servers.cfg"
const clients_config_file = configs_directory + "clients.cfg"
const default_server_config_file = source_directory + "default_server_config.cfg"
const default_client_config_file = source_directory + "default_client_config.cfg"
# why the fuck is there no text ressource - 28.06.2024
@export var scene_server_world: PackedScene
@export var scene_client_world: PackedScene
var game_main: GameMain
var func_u: GameMain.FuncU
var servers_config = ConfigFile.new()
var clients_config = ConfigFile.new()
var active_servers = {}
var active_clients = {}


func init(p_game_main: GameMain) -> void:
	game_main = p_game_main
	func_u = game_main.func_u
	
	if not DirAccess.dir_exists_absolute(configs_directory):
		func_u.create_directory(configs_directory)
	
	if not FileAccess.file_exists(servers_config_file):
		_save_servers_config()
	func_u.load_config_file(servers_config, servers_config_file)
	
	if not FileAccess.file_exists(clients_config_file):
		_save_clients_config()
	func_u.load_config_file(clients_config, clients_config_file)


func _exit_tree() -> void:
	_save_servers_config()
	_save_clients_config()


func create_server_world(display_name: String) -> String:
	var new_world_directory = configs_directory.path_join(display_name.to_snake_case() + "_" + "server_" + str(Time.get_unix_time_from_system()))
	func_u.create_directory(new_world_directory)
	
	servers_config.set_value(new_world_directory, "hidden", false)
	_save_servers_config()
	
	var new_world_config = ConfigFile.new()
	func_u.load_config_file(new_world_config, default_server_config_file)
	
	new_world_config.set_value("general", "name", display_name)
	func_u.save_config_file(new_world_config, new_world_directory.path_join("world.cfg"))
	return new_world_directory


# TODO: custom object for options instead of Dictionary
func create_client_world(display_name: String, options: Dictionary) -> String:
	var new_world_directory = configs_directory.path_join(display_name.to_snake_case() + "_" + "client_" + str(Time.get_unix_time_from_system()))
	func_u.create_directory(new_world_directory)
	
	clients_config.set_value(new_world_directory, "hidden", options.has("server_world_directory"))
	
	_save_clients_config()
	
	var new_world_config = ConfigFile.new()
	func_u.load_config_file(new_world_config, default_client_config_file)
	
	new_world_config.set_value("general", "name", display_name)
	if options.has("server_world_directory"):
		new_world_config.set_value("general", "server_world_directory", options.server_world_directory)
	else:
		new_world_config.set_value("general", "server_ip", options.ip)
		new_world_config.set_value("general", "server_port", options.port)
	
	func_u.save_config_file(new_world_config, new_world_directory.path_join("world.cfg"))
	return new_world_directory


func delete_server_world(path: String) -> void:
	func_u.delete_recursively(path)
	unlink_server_world(path)


func delete_client_world(path: String) -> void:
	func_u.delete_recursively(path)
	unlink_client_world(path)


func unlink_server_world(path: String) -> void:
	servers_config.erase_section(path)
	_save_servers_config()


func unlink_client_world(path: String) -> void:
	clients_config.erase_section(path)
	_save_clients_config()


func _save_servers_config() -> void:
	func_u.save_config_file(servers_config, servers_config_file)


func _save_clients_config() -> void:
	func_u.save_config_file(clients_config, clients_config_file)


func start_server(world_directory: String) -> Server:
	var new_server: Server = scene_server_world.instantiate()
	add_child(new_server)
	new_server.init(game_main, world_directory)
	active_servers[world_directory] = new_server
	new_server.stopping.connect(func():
		active_servers.erase(new_server)
	)
	new_server.start()
	return new_server


func start_client(world_directory: String) -> Client:
	var new_client: Client = scene_client_world.instantiate()
	add_child(new_client)
	new_client.init(game_main, world_directory)
	active_clients[world_directory] = new_client
	new_client.stopping.connect(func():
		active_clients.erase(new_client)
	)
	new_client.start()
	return new_client
