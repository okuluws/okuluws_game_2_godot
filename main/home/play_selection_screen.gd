extends Control


# REQUIRED
@export var home: Node

@export var scene_world_display: PackedScene
@export var scene_server_display: PackedScene
@export var scene_active_server_display: PackedScene
@export var vbox_world_list: VBoxContainer
@export var vbox_server_list: VBoxContainer
@export var vbox_active_servers_list: VBoxContainer
@export var world_deletion_confirmation_window: ConfirmationDialog
@onready var main = home.main
@onready var worlds_config: ConfigFile = main.modules.worlds.servers_config
@onready var clients_config: ConfigFile = main.modules.worlds.clients_config
var selected_world
var selected_server


func _ready():
	load_world_list()
	load_server_list()
	load_active_servers_list()


func load_world_list():
	for c in vbox_world_list.get_children():
		c.queue_free()
	
	var c = ConfigFile.new()
	var err
	for s in worlds_config.get_sections():
		err = main.modules.func_u.ConfigFile_load(c, s.path_join("world.cfg"))
		if err != null:
			push_error(err)
			push_error("couldn't load world config for %s" % s)
			continue
		
		var display_name = c.get_value("general", "name")
		var new_world_display = scene_world_display.instantiate()
		new_world_display.label_display_name.text = display_name
		new_world_display.pressed.connect(func(): selected_world = s)
		vbox_world_list.add_child(new_world_display)


func load_server_list():
	for c in vbox_server_list.get_children():
		c.queue_free()
	
	for s in clients_config.get_sections():
		var display_name = clients_config.get_value(s, "general/name")
		var new_server_display = scene_server_display.instantiate()
		new_server_display.label_display_name.text = display_name
		new_server_display.pressed.connect(func(): selected_server = s)
		vbox_server_list.add_child(new_server_display)


func load_active_servers_list():
	for c in vbox_active_servers_list.get_children():
		c.queue_free()
	
	for s in main.modules.worlds.active_servers.keys():
		var new_active_server_display = scene_active_server_display.instantiate()
		new_active_server_display.server_name_label.text = s.world_dir_path
		vbox_active_servers_list.add_child(new_active_server_display)
	


func _on_btn_create_world_pressed():
	home.show_create_world_screen()
	queue_free()


func _on_btn_back_arrow_pressed():
	home.show_title_screen()
	queue_free()


func _on_btn_add_server_pressed():
	home.show_add_server_screen()
	queue_free()


func _on_btn_remove_server_pressed():
	if selected_server == null:
		return
	
	main.modules.worlds.remove_client_config(selected_server)
	load_server_list()


func _on_btn_delete_world_pressed():
	if selected_world == null:
		return
	
	world_deletion_confirmation_window.visible = true


func _on_delete_local_world_confirmation_dialog_confirmed():
	if selected_world == null:
		return
	
	main.modules.worlds.delete_world(selected_world)
	selected_world = null
	load_world_list()


func _on_btn_start_world_pressed():
	if selected_world == null:
		return
	
	main.modules.worlds.start_client_local(main.modules.worlds.start_server(selected_world))


func _on_btn_edit_world_pressed():
	if selected_world == null:
		return
	
	home.show_local_world_config_screen(selected_world)
	queue_free()


