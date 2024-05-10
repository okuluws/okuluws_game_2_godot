extends CanvasLayer


const Home = preload("./home.gd")
@onready var home: Home = get_parent()


func _on_multiplayer_pressed() -> void:
	home.add_child(home.server_selection_scene.instantiate())
	queue_free()
	


func _on_singleplayer_pressed() -> void:
	home.add_child(home.world_selection_scene.instantiate())
	queue_free()
	


func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
