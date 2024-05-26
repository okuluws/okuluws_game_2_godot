extends CanvasLayer


@onready var home = $"../"
@onready var virtual_joystick_value_label = $"TabContainer/General/VirtualJoystickButton/Label2"
@onready var content_scale_size_value_label = $"TabContainer/General/ResolutionButton/Label2"
@onready var save_button = $"Save"


func _ready():
	_display_config()


func _display_config():
	virtual_joystick_value_label.text = "Enabled" if home.config.get_value("gameplay", "virtual_joystick") else "Disabled"
	var content_scale_size_value = home.config.get_value("video", "content_scale_size")
	content_scale_size_value_label.text = "%dx%d" % [content_scale_size_value.x, content_scale_size_value.y]
	
	save_button.disabled = home.config.encode_to_text().hash() == home.latest_load_config_hash
	
	


func _on_back_pressed():
	home.config.clear()
	home.load_config()
	home.add_child(load("res://home/title_screen.tscn").instantiate())
	queue_free()


func _on_virtual_joystick_button_pressed():
	home.config.set_value("gameplay", "virtual_joystick", not home.config.get_value("gameplay", "virtual_joystick"))
	_display_config()


func _on_resolution_button_pressed():
	home.config.set_value("video", "content_scale_size", Vector2(1920, 1080))
	_display_config()


func _on_save_pressed():
	home.save_config()
	home.load_config()
	_ready()


func _on_reset_config_button_pressed():
	home.save_standart_config()
	home.load_config()
	_ready()
