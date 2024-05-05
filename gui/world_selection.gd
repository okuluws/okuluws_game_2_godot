extends CanvasLayer


@onready var Main: Node = $"/root/Main"
@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"


func _on_new_world_pressed():
	var World = preload("res://globals/World.tscn").instantiate()
	World.WORLD_FOLDER = preload("res://globals/World.gd").create_world_folder("New World")
	Main.add_child(World)
	World.start_local()
	queue_free()
	


func _on_back_pressed():
	GUIs.add_child(preload("res://gui/home.tscn").instantiate())
	queue_free()
	

func _ready():
	var worlds_folder = DirAccess.open("user://worlds")
	for dir_name in worlds_folder.get_directories():
		var world_config = ConfigFile.new()
		world_config.load("user://worlds/%s/config.cfg" % dir_name)
		var world_display = preload("res://gui/world_display.tscn").instantiate()
		world_display.world_name.text = dir_name
		world_display.playtime.text = str(world_config.get_value("_", "playtime"))
		world_display.version.text = world_config.get_value("_", "version")
		$"ScrollContainer/VBoxContainer".add_child(world_display)
