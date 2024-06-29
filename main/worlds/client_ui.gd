extends CanvasLayer


# REQUIRED
var client: Node

@export var escape_panel: Panel


func _on_resume_button_pressed():
	escape_panel.visible = false


func _on_open_lan_button_pressed():
	pass # Replace with function body.


func _on_quit_world_button_pressed():
	client.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_open_escape_panel_button_pressed():
	escape_panel.visible = not escape_panel.visible








