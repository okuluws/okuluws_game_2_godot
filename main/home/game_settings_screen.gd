extends CanvasLayer


var home


func _on_back_pressed():
	home.show_title_screen()
	queue_free()


# TODO: account settings, world settings, video settings
