extends CanvasLayer


@export_file("*.tscn") var server_selection_file
@export_file("*.tscn") var world_selection_file


func _on_multiplayer_pressed() -> void:
	get_parent().add_child(load(server_selection_file).instantiate())
	queue_free()
	


func _on_singleplayer_pressed() -> void:
	get_parent().add_child(load(world_selection_file).instantiate())
	queue_free()
	


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
