extends Control


# REQUIRED
@export var home: Node


func _on_play_pressed():
	home.show_menu("play_selection_screen")


func _on_settings_pressed():
	pass


func _on_quit_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
