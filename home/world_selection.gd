extends CanvasLayer


@export var FuncU: Script
@export var WORLDS_FOLDER_NAME: String = "worlds"
@export var WORLD_CONFIG_FILENAME: String = "config.cfg"
@export_file("*.gd") var world_script
@export_file("*.tscn") var world_file
@export_file("*.tscn") var title_screen_file
@export_file("*.tscn") var world_edit_file
@export_file("*.tscn") var world_display_file
@export var world_display_vbox: VBoxContainer

var selected_world_folder_name: String


func _on_new_world_pressed() -> void:
	load(world_script).create_world_folder("New World")
	load_world_displays()


func _on_back_pressed() -> void:
	get_parent().add_child(load(title_screen_file).instantiate())
	queue_free()
	

func _ready() -> void:
	load_world_displays()


func _on_join_world_pressed() -> void:
	var Server = load(world_file).instantiate()
	$"../../GUIs/SubViewportContainer2/SubViewport".add_child(Server)
	Server.start_server(selected_world_folder_name, "127.0.0.1:42000")
	var Client = load(world_file).instantiate()
	$"../../GUIs/SubViewportContainer1/SubViewport".add_child(Client)
	Client.start_client("127.0.0.1:42000")
	queue_free()
	


func _on_edit_world_pressed() -> void:
	var world_edit = load(world_edit_file).instantiate()
	world_edit.setup("user://%s/%s" % [WORLDS_FOLDER_NAME, selected_world_folder_name])
	get_parent().add_child(world_edit)
	queue_free()
	


func load_world_displays() -> void:
	var worlds_folder := DirAccess.open("user://%s" % WORLDS_FOLDER_NAME)
	for dir_name in worlds_folder.get_directories():
		var world_config = FuncU.BetterConfigFile.new("%s/%s/%s" % [worlds_folder.get_current_dir(), dir_name, WORLD_CONFIG_FILENAME])
		var world_display = load(world_display_file).instantiate()
		world_display.world_name.text = world_config.get_base_value("name")
		world_display.playtime.text = "Playtime: %s" % FuncU.s_to_hhmmss(world_config.get_base_value("playtime"))
		world_display.version.text = "version %s" % world_config.get_base_value("version")
		world_display.pressed.connect(func() -> void:
			selected_world_folder_name = dir_name
			$"Join World".disabled = false
			$"Edit World".disabled = false
		)
		$"ScrollContainer/VBoxContainer".add_child(world_display)

