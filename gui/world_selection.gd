extends CanvasLayer


@onready var Main: Node = $"/root/Main"
@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"
const FuncU = preload("res://globals/FuncU.gd")

var selected_world_folder: String


func _on_new_world_pressed():
	preload("res://globals/World.gd").create_world_folder("New World")
	load_world_displays()
	


func _on_back_pressed():
	GUIs.add_child(preload("res://gui/home.tscn").instantiate())
	queue_free()
	

func _ready():
	load_world_displays()


func _on_join_world_pressed():
	var Server = preload("res://globals/World.tscn").instantiate()
	Main.get_node("GUIs/SubViewportContainer2/SubViewport").add_child(Server)
	Server.start_server(selected_world_folder, "127.0.0.1:42000")
	var Client = preload("res://globals/World.tscn").instantiate()
	Main.get_node("GUIs/SubViewportContainer/SubViewport").add_child(Client)
	Client.start_client("127.0.0.1:42000")
	queue_free()
	


func _on_edit_world_pressed():
	var world_edit_scene = preload("res://gui/world_edit.tscn").instantiate()
	world_edit_scene.setup(selected_world_folder)
	GUIs.add_child(world_edit_scene)
	queue_free()
	


func load_world_displays():
	var worlds_folder = DirAccess.open("user://worlds")
	for dir_name in worlds_folder.get_directories():
		var world_config = FuncU.BetterConfigFile.new("%s/%s/config.cfg" % [worlds_folder.get_current_dir(), dir_name])
		var world_display = preload("res://gui/world_display.tscn").instantiate()
		world_display.world_name.text = world_config.get_base_value("name")
		world_display.playtime.text = "Playtime: %s" % FuncU.s_to_hhmmss(world_config.get_base_value("playtime"))
		world_display.version.text = "version %s" % world_config.get_base_value("version")
		world_display.pressed.connect(func():
			selected_world_folder = "%s/%s" % [worlds_folder.get_current_dir(), dir_name]
			$"Join World".disabled = false
			$"Edit World".disabled = false
		)
		$"ScrollContainer/VBoxContainer".add_child(world_display)

