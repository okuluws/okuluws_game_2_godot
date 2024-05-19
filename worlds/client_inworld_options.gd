extends CanvasLayer


@export var quit_world_button: Button


func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		visible = not visible

func _on_resume_pressed():
	visible = false


func _on_quit_world_pressed():
	$"../".queue_free()
	$"/root/Main/Home".add_child(load($"/root/Main/Home".title_screen_file).instantiate())


func _on_open_lan_pressed():
	pass # Replace with function body.
