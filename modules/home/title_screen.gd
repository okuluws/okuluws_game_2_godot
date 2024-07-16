extends Control


const Home = preload("main.gd")
var home: Home


func init(p_home: Home):
	home = p_home


func _on_play_pressed() -> void:
	home.show_play_selection_screen()
	queue_free()


func _on_settings_pressed() -> void:
	home.show_game_settings_screen()
	queue_free()


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
