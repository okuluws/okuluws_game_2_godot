extends CanvasLayer


@onready var main: Main = $"/root/Main"
const FuncU = preload("res://globals/FuncU.gd")

var selected_world_folder_name: String


func _on_new_world_pressed() -> void:
	main.world_class.create_world_folder(main, "New World")
	load_world_displays()


func _on_back_pressed() -> void:
	main.GUIs.add_child(main.home_scene.instantiate())
	queue_free()
	

func _ready() -> void:
	load_world_displays()


func _on_join_world_pressed() -> void:
	var Server: Main.world_class = main.world_scene.instantiate()
	main.GUIs.get_node("SubViewportContainer2/SubViewport").add_child(Server)
	Server.start_server(selected_world_folder_name, "127.0.0.1:42000")
	var Client: Main.world_class = main.world_scene.instantiate()
	main.GUIs.get_node("SubViewportContainer/SubViewport").add_child(Client)
	Client.start_client("127.0.0.1:42000")
	queue_free()
	


func _on_edit_world_pressed() -> void:
	var world_edit: Main.world_edit_class = main.world_edit_scene.instantiate()
	world_edit.setup(main, "%s/%s" % [main.worlds_folder, selected_world_folder_name])
	main.GUIs.add_child(world_edit)
	queue_free()
	


func load_world_displays() -> void:
	var worlds_folder := DirAccess.open(main.worlds_folder)
	for dir_name in worlds_folder.get_directories():
		var world_config := FuncU.BetterConfigFile.new("%s/%s/%s" % [worlds_folder.get_current_dir(), dir_name, main.WORLD_CONFIG_FILENAME])
		
		var world_display: Main.world_display_class = main.world_display_scene.instantiate()
		world_display.world_name.text = world_config.get_base_value("name")
		world_display.playtime.text = "Playtime: %s" % FuncU.s_to_hhmmss(world_config.get_base_value("playtime") as float)
		world_display.version.text = "version %s" % world_config.get_base_value("version")
		world_display.pressed.connect(func() -> void:
			selected_world_folder_name = dir_name
			($"Join World" as Button).disabled = false
			($"Edit World" as Button).disabled = false
		)
		$"ScrollContainer/VBoxContainer".add_child(world_display)

