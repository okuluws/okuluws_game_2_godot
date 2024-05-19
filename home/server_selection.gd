extends CanvasLayer


const servers_config_file = "user://servers.cfg"
const server_display_file = "res://home/server_display.tscn"
@export var server_address_edit: LineEdit
@export var server_list_vbox: VBoxContainer
@export var join_server_button: Button
@export var edit_server_button: Button
@export var remove_server_button: Button

var selected_server = ""


func _ready():
	if not FileAccess.file_exists(servers_config_file): FileAccess.open(servers_config_file, FileAccess.WRITE)
	load_server_list()


func _on_back_pressed() -> void:
	get_parent().add_child(load(get_parent().title_screen_file).instantiate())
	queue_free()
	

func _on_join_server_pressed() -> void:
	$"../../Worlds".make_client(selected_server)
	queue_free()
	

#func _on_host_locally_pressed() -> void:
	#$"../../Worlds".make_server("%s/New World" % $"../../Worlds".WORLDS_DIR, server_address_edit.text)
	#queue_free()
	#


func _on_add_server_pressed():
	var servers_cfg = ConfigFile.new()
	servers_cfg.load(servers_config_file)
	servers_cfg.set_value(server_address_edit.text, "name", server_address_edit.text)
	servers_cfg.save(servers_config_file)
	load_server_list()


func _on_edit_server_pressed():
	pass # Replace with function body.


func load_server_list():
	for c in server_list_vbox.get_children():
		server_list_vbox.remove_child(c)
	
	var servers_cfg = ConfigFile.new()
	servers_cfg.load(servers_config_file)
	
	
	for section in servers_cfg.get_sections():
		var server_name = servers_cfg.get_value(section, "name")
		var new_server_display = load(server_display_file).instantiate()
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
	servers_cfg.load(servers_config_file)
	servers_cfg.erase_section(selected_server)
	servers_cfg.save(servers_config_file)
	selected_server = ""
	join_server_button.disabled = true
	edit_server_button.disabled = true
	remove_server_button.disabled = true
	load_server_list()
