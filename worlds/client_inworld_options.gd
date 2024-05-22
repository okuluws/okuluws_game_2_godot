extends CanvasLayer


@export var quit_world_button: Button
@onready var client = $"../"


func _on_resume_pressed():
	visible = false


func _on_quit_world_pressed():
	client.quit_world()


func _on_open_lan_pressed():
	pass # Replace with function body.


func _on_open_toggled(toggled_on):
	if toggled_on:
		$"CanvasLayer".visible = true
	else:
		$"CanvasLayer".visible = false
