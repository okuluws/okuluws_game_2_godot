extends CanvasLayer


const servers_config_path = "user://servers.cfg"
@export var server_address_edit: LineEdit
@export var server_list_vbox: VBoxContainer
@export var join_server_button: Button
@export var edit_server_button: Button
@export var remove_server_button: Button
@onready var home = $"../"
@onready var worlds_handler = $"../../Worlds"
var selected_server


func _ready():
	if not FileAccess.file_exists(servers_config_path): FileAccess.open(servers_config_path, FileAccess.WRITE)
	load_server_list()


func _on_back_pressed() -> void:
	home.add_child(load("res://home/title_screen.tscn").instantiate())
	queue_free()
	

func _on_join_server_pressed() -> void:
	worlds_handler.make_client(selected_server)
	queue_free()
	

#func _on_host_locally_pressed() -> void:
	#$"../../Worlds".make_server("%s/New World" % $"../../Worlds".WORLDS_DIR, server_address_edit.text)
	#queue_free()
	#


func _on_add_server_pressed():
	var servers_cfg = ConfigFile.new()
	servers_cfg.load(servers_config_path)
	servers_cfg.set_value(server_address_edit.text, "name", server_address_edit.text)
	servers_cfg.save(servers_config_path)
	load_server_list()


func _on_edit_server_pressed():
	pass # Replace with function body.


func load_server_list():
	for c in server_list_vbox.get_children():
		server_list_vbox.remove_child(c)
	
	var servers_cfg = ConfigFile.new()
	servers_cfg.load(servers_config_path)
	
	
	for section in servers_cfg.get_sections():
		var server_name = servers_cfg.get_value(section, "name")
		var new_server_display = load("res://home/server_display.tscn").instantiate()
		new_server_display.server_name_label.text = server_name
		new_server_display.pressed.connect(func():
			selected_server = section
			join_server_button.disabled = false
			edit_server_button.disabled = false
			remove_server_button.disabled = false
		)
		server_list_vbox.add_child(new_server_display)
	

func _on_remove_server_pressed():
	var servers_cfg = ConfigFile.new()
	servers_cfg.load(servers_config_path)
	servers_cfg.erase_section(selected_server)
	servers_cfg.save(servers_config_path)
	selected_server = null
	join_server_button.disabled = true
	edit_server_button.disabled = true
	remove_server_button.disabled = true
	load_server_list()
