extends CanvasLayer


const FuncU = preload("res://globals/FuncU.gd")
const WORLDS_FOLDER = "user://worlds"
const WORLD_CONFIG_FILENAME = "config.cfg"
const Home = preload("./home.gd")
@onready var home: Home = get_parent()
@onready var world_display_vbox: VBoxContainer = $"ScrollContainer/VBoxContainer"

var selected_world_folder_name: String


func _on_new_world_pressed() -> void:
	preload("res://world/World.gd").create_world_folder("New World")
	load_world_displays()


func _on_back_pressed() -> void:
	home.add_child(home.title_screen_scene.instantiate())
	queue_free()
	

func _ready() -> void:
	load_world_displays()


func _on_join_world_pressed() -> void:
	var Server: Home.World = home.world_scene.instantiate()
	home.main.GUIs.get_node("SubViewportContainer2/SubViewport").add_child(Server)
	Server.start_server(selected_world_folder_name, "127.0.0.1:42000")
	var Client: Home.World = home.world_scene.instantiate()
	home.main.GUIs.get_node("SubViewportContainer1/SubViewport").add_child(Client)
	Client.start_client("127.0.0.1:42000")
	queue_free()
	


func _on_edit_world_pressed() -> void:
	var world_edit: Home.WorldEdit = home.world_edit_scene.instantiate()
	world_edit.setup("%s/%s" % [WORLDS_FOLDER, selected_world_folder_name])
	home.add_child(world_edit)
	queue_free()
	


func load_world_displays() -> void:
	var worlds_folder := DirAccess.open(WORLDS_FOLDER)
	for dir_name in worlds_folder.get_directories():
		var world_config := FuncU.BetterConfigFile.new("%s/%s/%s" % [worlds_folder.get_current_dir(), dir_name, WORLD_CONFIG_FILENAME])
		
		var world_display: Home.WorldDisplay = home.world_display_scene.instantiate()
		world_display.world_name.text = world_config.get_base_value("name")
		world_display.playtime.text = "Playtime: %s" % FuncU.s_to_hhmmss(world_config.get_base_value("playtime") as float)
		world_display.version.text = "version %s" % world_config.get_base_value("version")
		world_display.pressed.connect(func() -> void:
			selected_world_folder_name = dir_name
			($"Join World" as Button).disabled = false
			($"Edit World" as Button).disabled = false
		)
		$"ScrollContainer/VBoxContainer".add_child(world_display)

