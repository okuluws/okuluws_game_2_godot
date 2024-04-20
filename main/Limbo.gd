extends Control


func _process(_delta):
	position = get_global_mouse_position() - size / 2
