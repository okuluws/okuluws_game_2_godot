extends CanvasLayer


@export var server_selection_scene: PackedScene
@export var world_selection_scene: PackedScene


func _on_multiplayer_pressed() -> void:
	get_parent().add_child(server_selection_scene.instantiate())
	queue_free()
	


func _on_singleplayer_pressed() -> void:
	get_parent().add_child(world_selection_scene.instantiate())
	queue_free()
	


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
