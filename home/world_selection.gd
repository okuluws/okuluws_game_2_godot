extends CanvasLayer


const WORLDS_DIR = "user://worlds"
@export var world_display_vbox: VBoxContainer
@onready var worlds_handler = $"../../Worlds"
@onready var home = $"../"
var selected_world_dir


func _ready():
	load_world_displays()
	

func _on_new_world_pressed():
	var world_name = "New World"
	var world_dir = WORLDS_DIR.path_join(world_name)
	var n = 1
	while DirAccess.dir_exists_absolute(world_dir):
		world_dir = WORLDS_DIR.path_join("%s (%d)" % [world_name, n])
		n += 1
	worlds_handler.create_world_folder(world_dir, world_name)
	selected_world_dir = world_dir
	load_world_displays()
	

func _on_back_pressed():
	home.add_child(load("res://home/title_screen.tscn").instantiate())
	queue_free()
	

func _on_join_world_pressed():
	worlds_handler.make_singleplayer(selected_world_dir)
	queue_free()
	

func _on_edit_world_pressed():
	var world_edit = load("res://home/world_edit.tscn").instantiate()
	world_edit.world_dir = selected_world_dir
	home.add_child(world_edit)
	queue_free()
	

func load_world_displays():
	for c in world_display_vbox.get_children():
		world_display_vbox.remove_child(c)
	
	for dirname in DirAccess.open(WORLDS_DIR).get_directories():
		var dir = WORLDS_DIR.path_join(dirname)
		var world_config = ConfigFile.new()
		if world_config.load(dir.path_join("config.cfg")) != OK: push_error(); return
		var world_display = load("res://home/world_display.tscn").instantiate()
		world_display.world_name.text = world_config.get_value("", "name")
		world_display.playtime.text = "Playtime: %s" % _s_to_hhmmss(world_config.get_value("", "playtime"))
		world_display.version.text = "version %s" % world_config.get_value("", "version")
		world_display.pressed.connect(func():
			selected_world_dir = dir
			$"Join World".disabled = false
			$"Edit World".disabled = false
			$"Host World".disabled = false
		)
		world_display_vbox.add_child(world_display)
	

func _on_host_world_pressed():
	worlds_handler.make_server(selected_world_dir, "*:42000")
	queue_free()


func _s_to_hhmmss(total_seconds: float) -> String:
	var seconds:float = fmod(total_seconds , 60.0)
	var minutes:int   =  int(total_seconds / 60.0) % 60
	var hours:  int   =  int(total_seconds / 3600.0)
	var hhmmss_string:String = "%02dh %02dmin %02.1fs" % [hours, minutes, seconds]
	return hhmmss_string


