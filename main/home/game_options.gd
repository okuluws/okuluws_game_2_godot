extends Control


# REQUIRED
var home

@onready var main = home.main
@export var virtual_joystick_value_label: Label
@export var content_scale_factor_value_label: Label
@export var content_scale_factor_slider: Slider
@export var save_button: BaseButton


func _ready():
	_display_config()


func _display_config():
	virtual_joystick_value_label.text = "Enabled" if main.get_virtual_joystick() else "Disabled"
	content_scale_factor_value_label.text = "%.1fx" % main.get_content_scale_factor()
	content_scale_factor_slider.set_value_no_signal(main.get_content_scale_factor())
	save_button.disabled = not main.config_has_changes()


func _on_back_button_pressed():
	var new_title_screen = home.title_screen_scene.instantiate()
	new_title_screen.home = home
	home.add_child(new_title_screen)
	queue_free()


func _on_virtual_joystick_button_pressed():
	main.set_virtual_joystick(not main.get_virtual_joystick())
	_display_config()


func _on_content_scale_factor_slider_value_changed(value):
	main.set_content_scale_factor(value)
	_display_config()


func _on_save_button_pressed():
	main.apply_changes()
	main.save_config()
	_display_config()


func _on_reset_config_button_pressed():
	main.reset_config()
	_display_config()


