extends CanvasLayer


@onready var main: Main = $"/root/Main"


func _on_multiplayer_pressed():
	get_parent().add_child(main.server_selection_scene.instantiate())
	queue_free()
	


func _on_singleplayer_pressed():
	get_parent().add_child(main.world_selection_scene.instantiate())
	queue_free()
	


func _on_quit_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
