extends CanvasLayer


@onready var GUIs = $"../"


func _on_multiplayer_pressed():
	GUIs.add_child(preload("res://gui/server_selection.tscn").instantiate())
	queue_free()
	


func _on_singleplayer_pressed():
	GUIs.add_child(preload("res://gui/world_selection.tscn").instantiate())
	queue_free()
	


func _on_quit_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
