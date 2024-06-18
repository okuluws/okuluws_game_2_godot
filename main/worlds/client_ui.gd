extends CanvasLayer


# REQUIRED
var client

@export var escape_panel: Panel
@onready var worlds = client.worlds


func _on_resume_button_pressed():
	escape_panel.visible = false


func _on_open_lan_button_pressed():
	pass # Replace with function body.


func _on_quit_world_button_pressed():
	worlds.close_client(client)


func _on_open_escape_panel_button_pressed():
	escape_panel.visible = not escape_panel.visible








