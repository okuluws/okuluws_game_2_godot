extends CanvasLayer


@onready var main = $"/root/Main"
@onready var home = $"../"
@onready var virtual_joystick_value_label = $"TabContainer/General/VirtualJoystickButton/Label2"
@onready var content_scale_factor_value_label = $"TabContainer/General/ContentScaleFactorButton/Label2"
@onready var content_scale_factor_slider = $"TabContainer/General/ContentScaleFactorButton/ContentScaleFactorSlider"
@onready var save_button = $"Save"
var intermediate_config = ConfigFile.new()


func _ready():
	_display_config()


func _display_config():
	virtual_joystick_value_label.text = "Enabled" if main.get_virtual_joystick() else "Disabled"
	content_scale_factor_value_label.text = "%.1fx" % main.get_content_scale_factor()
	content_scale_factor_slider.set_value_no_signal(main.get_content_scale_factor())
	save_button.disabled = not main.config_has_changes()


func _on_back_pressed():
	home.add_child(load("res://home/title_screen.tscn").instantiate())
	queue_free()


func _on_virtual_joystick_button_pressed():
	main.set_virtual_joystick(not main.get_virtual_joystick())
	_display_config()


func _on_content_scale_factor_slider_value_changed(value):
	main.set_content_scale_factor(value)
	_display_config()


func _on_save_pressed():
	main.apply_changes()
	main.save_config()
	_display_config()


func _on_reset_config_button_pressed():
	main.reset_config()
	_display_config()





