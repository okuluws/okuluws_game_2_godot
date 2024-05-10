extends CanvasLayer


@onready var main: Main = $"/root/Main"

func _on_multiplayer_pressed() -> void:
	get_parent().add_child(main.server_selection_scene.instantiate())
	queue_free()
	


func _on_singleplayer_pressed() -> void:
	get_parent().add_child(main.world_selection_scene.instantiate())
	queue_free()
	


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
