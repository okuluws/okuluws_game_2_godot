extends Control


const Home = preload("main.gd")
const FuncU = preload("res://modules/func_u/func_u.gd")
@export var scene_server_display: PackedScene
@export var scene_client_display: PackedScene
@export var scene_active_server_display: PackedScene
@export var vbox_server_list: VBoxContainer
@export var vbox_client_list: VBoxContainer
@export var vbox_active_server_list: VBoxContainer
@export var world_deletion_confirmation_window: ConfirmationDialog
var home: Home
var game_main: Home.GameMain
var func_u: FuncU
var servers_config: ConfigFile
var clients_config: ConfigFile
var selected_server_world
var selected_client_world


func init(p_home: Home):
	home = p_home
	game_main = home.game_main
	func_u = game_main.modules.pocketbase
	servers_config = game_main.modules.worlds.servers_config
	clients_config = game_main.modules.worlds.clients_config


func _ready():
	load_server_list()
	load_client_list()


func load_server_list():
	for n in vbox_server_list.get_children():
		n.queue_free()
	
	for s in servers_config.get_sections():
		var cfg = ConfigFile.new()
		var err = func_u.ConfigFile_load(cfg, s.path_join("world.cfg"))
		if err != null:
			push_error(err)
			continue
		
		var new_world_display = scene_server_display.instantiate()
		new_world_display.label_display_name.text = cfg.get_value("general", "name")
		new_world_display.pressed.connect(func(): selected_server_world = s)
		vbox_server_list.add_child(new_world_display)


func load_client_list():
	for n in vbox_client_list.get_children():
		n.queue_free()
	
	for s in clients_config.get_sections():
		var cfg = ConfigFile.new()
		var err = func_u.ConfigFile_load(cfg, s.path_join("world.cfg"))
		if err != null:
			push_error(err)
			continue
		
		var new_server_display = scene_client_display.instantiate()
		new_server_display.label_display_name.text = cfg.get_value("general", "name")
		new_server_display.pressed.connect(func(): selected_client_world = s)
		vbox_client_list.add_child(new_server_display)


func load_active_servers_list():
	for c in vbox_active_server_list.get_children():
		c.queue_free()
	
	for s in game_main.modules.worlds.active_servers.keys():
		var new_active_server_display = scene_active_server_display.instantiate()
		new_active_server_display.server_name_label.text = s.world_dir_path
		vbox_active_server_list.add_child(new_active_server_display)
	


func _on_btn_create_world_pressed():
	home.show_server_creation_screen()
	queue_free()


func _on_btn_back_arrow_pressed():
	home.show_title_screen()
	queue_free()


func _on_btn_add_server_pressed():
	home.show_client_creation_screen()
	queue_free()


func _on_btn_remove_server_pressed():
	if selected_client_world == null:
		return
	
	game_main.modules.worlds.delete_client_world(selected_client_world)
	load_client_list()


func _on_btn_delete_world_pressed():
	if selected_server_world == null:
		return
	
	world_deletion_confirmation_window.visible = true


func _on_delete_local_world_confirmation_dialog_confirmed():
	if selected_server_world == null:
		return
	
	game_main.modules.worlds.delete_server_world(selected_server_world)
	selected_server_world = null
	load_server_list()


func _on_btn_start_world_pressed():
	if selected_server_world == null:
		return
	
	#game_main.modules.worlds.start_client(game_main.modules.worlds.start_server(selected_server_world))
	game_main.modules.worlds.start_server(selected_server_world)


func _on_btn_edit_world_pressed():
	if selected_server_world == null:
		return
	
	home.show_server_config_screen(selected_server_world)
	queue_free()


func _on_btn_join_server_pressed():
	if selected_client_world == null:
		return
	
	game_main.modules.worlds.start_client(selected_client_world)
