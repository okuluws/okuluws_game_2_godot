extends CanvasLayer


const CONFIG_PATH = "user://options.cfg"
@onready var pocketbase = $"../Pocketbase"
var config = ConfigFile.new()
var latest_load_config_hash


func _ready():
	if not FileAccess.file_exists(CONFIG_PATH):
		save_standart_config()
	load_config()
	pocketbase.ready.connect(func(): add_child(load("res://home/title_screen.tscn").instantiate()))
	


func save_standart_config():
	config.clear()
	config.set_value("gameplay", "virtual_joystick", OS.has_feature("mobile"))
	config.set_value("video", "content_scale_size", Vector2(1152, 648))
	save_config()


func load_config():
	if config.load(CONFIG_PATH) != OK: push_error(); return
	latest_load_config_hash = config.encode_to_text().hash()
	get_tree().root.content_scale_size = config.get_value("video", "content_scale_size")


func save_config():
	if config.save(CONFIG_PATH) != OK: push_error(); return
	
