extends CanvasLayer


func _on_multiplayer_pressed() -> void:
	get_parent().add_child(load(get_parent().server_selection_file).instantiate())
	queue_free()
	


func _on_singleplayer_pressed() -> void:
	get_parent().add_child(load(get_parent().world_selection_file).instantiate())
	queue_free()
	


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
