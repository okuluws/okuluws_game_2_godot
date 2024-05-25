extends CanvasLayer


@onready var home = $"../"
@onready var virtual_joystick_value_label = $"TabContainer/General/VirtualJoystickButton/Label2"
@onready var content_scale_size_value_label = $"TabContainer/General/ResolutionButton/Label2"
@onready var save_button = $"Save"
var config = ConfigFile.new()
var start_config_hash


func _ready():
	if config.load("user://options.cfg") != OK: push_error(); _on_back_pressed(); return
	start_config_hash = config.encode_to_text().hash()
	_display_config()


func _display_config():
	virtual_joystick_value_label.text = "Enabled" if config.get_value("gameplay", "virtual_joystick") else "Disabled"
	var content_scale_size_value = config.get_value("video", "content_scale_size")
	content_scale_size_value_label.text = "%dx%d" % [content_scale_size_value.x, content_scale_size_value.y]
	
	save_button.disabled = config.encode_to_text().hash() == start_config_hash
	
	


func _on_back_pressed():
	home.add_child(load("res://home/title_screen.tscn").instantiate())
	queue_free()


func _on_virtual_joystick_button_pressed():
	config.set_value("gameplay", "virtual_joystick", not config.get_value("gameplay", "virtual_joystick"))
	_display_config()


func _on_resolution_button_pressed():
	config.set_value("video", "content_scale_size", Vector2(1920, 1080))
	_display_config()


func _on_save_pressed():
	config.save("user://options.cfg")
	home.load_config()
	_ready()


func _on_reset_config_button_pressed():
	home.setup_standart_config()
	home.load_config()
	_ready()
