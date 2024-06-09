extends Panel


# REQUIRED
var main

@onready var home = main.home
@onready var ui = main.ui
@onready var worlds = main.worlds
@export var server_address_line_edit: LineEdit
@export var server_list_vbox: VBoxContainer
@export var join_server_button: BaseButton
@export var edit_server_button: BaseButton
@export var remove_server_button: BaseButton
var servers_config_path = "user://servers.cfg"
var servers_config = ConfigFile.new()
var selected_server


func _ready():
	if servers_config.load(servers_config_path) == OK:
		display_server_list()
	else:
		print_debug("[%s] no servers config found" % Time.get_time_string_from_system())


func display_server_list():
	for c in server_list_vbox.get_children():
		server_list_vbox.remove_child(c)
	
	for section in servers_config.get_sections():
		var server_name = servers_config.get_value(section, "name")
		var new_server_display = home.server_display_scene.instantiate()
		new_server_display.server_name_label.text = server_name
		new_server_display.pressed.connect(func():
			selected_server = section
			join_server_button.disabled = false
			edit_server_button.disabled = false
			remove_server_button.disabled = false
		)
		server_list_vbox.add_child(new_server_display)


func _on_join_server_button_pressed():
	worlds.make_client(selected_server)
	queue_free()


func _on_edit_server_button_pressed():
	pass # Replace with function body.


func _on_remove_server_button_pressed():
	servers_config.erase_section(selected_server)
	servers_config.save(servers_config_path)
	selected_server = null
	join_server_button.disabled = true
	edit_server_button.disabled = true
	remove_server_button.disabled = true
	display_server_list()


func _on_back_button_pressed():
	var new_title_screen = home.title_screen_scene.instantiate()
	new_title_screen.main = main
	ui.add_child(new_title_screen)
	queue_free()


func _on_add_server_button_pressed():
	var n = 0
	while servers_config.has_section("%s" % n):
		n += 1
	servers_config.set_value("%s" % n, "name", server_address_line_edit.text)
	servers_config.save(servers_config_path)
	display_server_list()




