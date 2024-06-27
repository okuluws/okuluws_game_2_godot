extends Node


# REQUIRED
@export var main: Node

@export var scene_client_world: PackedScene
@export var scene_server_world: PackedScene
@onready var func_u = main.modules.func_u
var worlds_dir_path = "user://worlds"
var worlds_config = ConfigFile.new()
var worlds_config_file_path = worlds_dir_path.path_join("worlds.cfg")
var clients_config = ConfigFile.new()
var clients_config_file_path = worlds_dir_path.path_join("clients.cfg")
#var world_config_dir_name = "world.cfg"
#var clients = {}
#var servers = {}


func _ready():
	var err
	if not DirAccess.dir_exists_absolute(worlds_dir_path):
		err = func_u.DirAccess_make_dir_absolute(worlds_dir_path)
		if err != null: func_u.unreachable(err)
	
	if not FileAccess.file_exists(worlds_config_file_path):
		err = _save_worlds_config()
		if err != null: func_u.unreachable(err)
	else:
		err = func_u.ConfigFile_load(worlds_config, worlds_config_file_path)
		if err != null: func_u.unreachable(err)
	
	if not FileAccess.file_exists(clients_config_file_path):
		err = _save_worlds_config()
		if err != null: func_u.unreachable(err)
	else:
		err = func_u.ConfigFile_load(clients_config, clients_config_file_path)
		if err != null: func_u.unreachable(err)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_worlds_config()
		_save_clients_config()


func create_world(display_name: String):
	var err
	var world_id = display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system())
	var new_world_dir_path = worlds_dir_path.path_join(world_id)
	
	err = func_u.DirAccess_make_dir_absolute(new_world_dir_path)
	if err != null:
		return { "err": err, "ret": null }
	
	worlds_config.set_value(world_id, "path", new_world_dir_path)
	worlds_config.set_value(world_id, "display_name", display_name)
	worlds_config.set_value(world_id, "ip", "127.0.0.1")
	worlds_config.set_value(world_id, "port", 20070)
	
	err = _save_worlds_config()
	if err != null:
		return { "err": err, "ret": null }
	
	return { "err": null, "ret": world_id }


func add_client_config(display_name: String, ip: String, port: int):
	var client_world_id = display_name.to_snake_case() + "_" + str(Time.get_unix_time_from_system())
	
	clients_config.set_value(client_world_id, "display_name", display_name)
	clients_config.set_value(client_world_id, "ip", ip)
	clients_config.set_value(client_world_id, "port", port)
	
	var err = _save_clients_config()
	if err != null:
		return { "err": err, "ret": null }
	
	return { "err": null, "ret": client_world_id }


func remove_client_config(id: String):
	clients_config.erase_section(id)
	return _save_clients_config()


func unlink_world(id: String):
	worlds_config.erase_section(id)
	return _save_worlds_config()


func delete_world(id: String):
	func_u.delete_recursively(worlds_config.get_value(id, "path"))
	return unlink_world(id)


func _save_worlds_config():
	return func_u.ConfigFile_save(worlds_config, worlds_config_file_path)


func _save_clients_config():
	return func_u.ConfigFile_save(clients_config, clients_config_file_path)


func start_server(world_id: String):
	var new_server = scene_server_world.instantiate()
	new_server.worlds = self
	new_server.world_dir_path = worlds_config.get_value(world_id, "path")
	new_server.ip = worlds_config.get_value(world_id, "ip")
	new_server.port = worlds_config.get_value(world_id, "port")
	add_child(new_server)
	return new_server


func start_client(_id: String): pass
func start_client_local(server_node: Node):
	var new_client = scene_client_world.instantiate()
	new_client.worlds = self
	new_client.server_node = server_node
	add_child(new_client)


#func create_world_folder(world_dir_path, world_name):
	#var worlds_dir = DirAccess.open(worlds_dir_path)
	#if worlds_dir.dir_exists(world_dir_path): print_debug("world folder >%s< already exists" % world_dir_path); return
	#worlds_dir.make_dir(world_dir_path)
	#var world_config = ConfigFile.new()
	#world_config.set_value("", "name", world_name)
	#world_config.set_value("", "playtime", 0.0)
	#world_config.set_value("", "version", ProjectSettings.get_setting_with_override("application/config/version"))
	#if world_config.save(world_dir_path.path_join("config.cfg")) != OK: push_error(); return
#
#
#func make_client(server_address: String) -> Node:
	#var client = _setup_client(server_address)
	#add_child(client)
	#clients[client] = {}
	#return client
#
#
#func _setup_client(server_address: String) -> Node:
	#var client = client_world_scene.instantiate()
	#client.main = main
	#var a = _parse_server_address(server_address)
	#client.server_ip = a.ip
	#client.server_port = a.port
	#return client
#
#
#func make_server(world_dir_path: String, server_address: String) -> Node:
	#var server = _setup_server(world_dir_path, server_address)
	#add_child(server)
	#servers[server] = {}
	#return server
#
#
#func _setup_server(world_dir_path: String, server_address: String) -> Node:
	#var server = server_world_scene.instantiate()
	#server.main = main
	#var a = _parse_server_address(server_address)
	#server.world_dir_path = world_dir_path
	#server.server_ip = a.ip
	#server.server_port = a.port
	#return server
#
#
#func make_singleplayer(world_dir_path: String) -> Dictionary:
	#var server = server_world_scene.instantiate()
	#server.worlds = self
	#server.world_dir_path = world_dir_path
	#server.server_port = 42123
	#server.server_ip = "127.0.0.1"
	#add_child(server)
	#servers[server] = {}
	#
	#var client = client_world_scene.instantiate()
	#client.worlds = self
	#client.server_port = 42123
	#client.server_ip = "127.0.0.1"
	#var ret = server.create_ticket("-1", "Offline Player")
	#client.ticket_id = ret.id
	#client.ticket_key = ret.key
	#add_child(client)
	#clients[client] = {}
	#
	#return { "server": server, "client": client }
#
#
## TODO: Support shortened / shortcut ip addresses like 0.0.0.0 or ::1
#func _parse_server_address(s: String):
	#var port_str = s.split(":")[-1]
	#return { "ip": s.trim_suffix(":%s" % port_str).lstrip("[").rstrip("]"), "port": int(port_str) }
#
#
#func _notification(what: int) -> void:
	#if what == NOTIFICATION_WM_CLOSE_REQUEST:
		#for c in clients:
			#close_client(c)
		#for s in servers:
			#close_server(s)
#
#
#func close_client(node):
	#node.queue_free()
	#clients.erase(node)
#
#
#func close_server(node):
	#node.queue_free()
	#servers.erase(node)
#
