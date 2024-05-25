extends CanvasLayer


const CONFIG_PATH = "user://options.cfg"
@onready var pocketbase = $"../Pocketbase"
var config = ConfigFile.new()


func _ready():
	if not FileAccess.file_exists(CONFIG_PATH):
		setup_standart_config()
	load_config()
	pocketbase.ready.connect(func(): add_child(load("res://home/title_screen.tscn").instantiate()))
	


func setup_standart_config():
	config.clear()
	config.set_value("gameplay", "virtual_joystick", OS.has_feature("mobile"))
	config.set_value("video", "content_scale_size", Vector2(1152, 648))
	if config.save(CONFIG_PATH) != OK: push_error(); return
	


func load_config():
	if config.load(CONFIG_PATH) != OK: push_error(); return
	get_tree().root.content_scale_size = config.get_value("video", "content_scale_size")
