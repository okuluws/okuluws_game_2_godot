extends CanvasLayer


const FuncU = preload("res://globals/FuncU.gd")
@export var world_display_vbox: VBoxContainer
var selected_world_folder_name: String


func _ready() -> void:
	load_world_displays()
	

func _on_new_world_pressed() -> void:
	$"../../Worlds".create_world_folder("New World")
	selected_world_folder_name = "New World"
	load_world_displays()
	

func _on_back_pressed() -> void:
	get_parent().add_child(load(get_parent().title_screen_file).instantiate())
	queue_free()
	

func _on_join_world_pressed() -> void:
	$"../../Worlds".make_server_and_client("%s/%s" % [$"../../Worlds".WORLDS_DIR, selected_world_folder_name])
	queue_free()
	

func _on_edit_world_pressed() -> void:
	var world_edit = load(get_parent().world_edit_file).instantiate()
	world_edit.setup("%s/%s" % [$"../../Worlds".WORLDS_DIR, selected_world_folder_name])
	get_parent().add_child(world_edit)
	queue_free()
	

func load_world_displays() -> void:
	for c in $"ScrollContainer/VBoxContainer".get_children():
		$"ScrollContainer/VBoxContainer".remove_child(c)
	
	var worlds_folder := DirAccess.open($"../../Worlds".WORLDS_DIR)
	for dir_name in worlds_folder.get_directories():
		var world_config = FuncU.BetterConfigFile.new("%s/%s/%s" % [worlds_folder.get_current_dir(), dir_name, $"../../Worlds".WORLD_CONFIG_FILENAME])
		var world_display = load(get_parent().world_display_file).instantiate()
		world_display.world_name.text = world_config.get_base_value("name")
		world_display.playtime.text = "Playtime: %s" % FuncU.s_to_hhmmss(world_config.get_base_value("playtime"))
		world_display.version.text = "version %s" % world_config.get_base_value("version")
		world_display.pressed.connect(func() -> void:
			selected_world_folder_name = dir_name
			$"Join World".disabled = false
			$"Edit World".disabled = false
		)
		$"ScrollContainer/VBoxContainer".add_child(world_display)
	
