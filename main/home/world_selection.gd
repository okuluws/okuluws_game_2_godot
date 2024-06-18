extends Control


# REQUIRED
var home

@onready var worlds = home.main.worlds
@export var world_display_vbox: VBoxContainer
@export var join_world_button: BaseButton
@export var edit_world_button: BaseButton
@export var host_world_button: BaseButton
var worlds_dir_path = "user://worlds"
var selected_world_dir_path


func _ready():
	load_world_displays()


func _on_join_world_button_pressed():
	worlds.make_singleplayer(selected_world_dir_path)
	queue_free()


func _on_edit_world_button_pressed():
	var new_world_edit = home.world_edit_scene.instantiate()
	new_world_edit.home = home
	new_world_edit.world_dir_path = selected_world_dir_path
	home.add_child(new_world_edit)
	queue_free()


func _on_host_world_button_pressed():
	worlds.make_server(selected_world_dir_path, "*:42000")
	queue_free()


func _on_new_world_button_pressed():
	var world_name = "New World"
	var world_dir_path = worlds_dir_path.path_join(world_name)
	var n = 1
	while DirAccess.dir_exists_absolute(world_dir_path):
		world_dir_path = worlds_dir_path.path_join("%s (%d)" % [world_name, n])
		n += 1
	worlds.create_world_folder(world_dir_path, world_name)
	selected_world_dir_path = world_dir_path
	load_world_displays()


func _on_back_button_pressed():
	var new_title_screen = home.title_screen_scene.instantiate()
	new_title_screen.home = home
	home.add_child(new_title_screen)
	queue_free()


func load_world_displays():
	for c in world_display_vbox.get_children():
		world_display_vbox.remove_child(c)
	
	for dirname in DirAccess.open(worlds_dir_path).get_directories():
		var dir_path = worlds_dir_path.path_join(dirname)
		var world_config = ConfigFile.new()
		if world_config.load(dir_path.path_join("config.cfg")) != OK: push_error(); return
		var new_world_display = home.world_display_scene.instantiate()
		new_world_display.world_name_rich_label.text = world_config.get_value("", "name")
		new_world_display.playtime_rich_label.text = "Playtime: %s" % _format_seconds(world_config.get_value("", "playtime"))
		new_world_display.version_rich_label.text = "version %s" % world_config.get_value("", "version")
		new_world_display.pressed.connect(func():
			selected_world_dir_path = dir_path
			join_world_button.disabled = false
			edit_world_button.disabled = false
			host_world_button.disabled = false
		)
		world_display_vbox.add_child(new_world_display)


func _format_seconds(total_seconds: float) -> String:
	var seconds:float = fmod(total_seconds , 60.0)
	var minutes:int   =  int(total_seconds / 60.0) % 60
	var hours:  int   =  int(total_seconds / 3600.0)
	var hhmmss_string:String = "%02dh %02dmin %02.1fs" % [hours, minutes, seconds]
	return hhmmss_string


