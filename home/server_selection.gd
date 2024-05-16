extends CanvasLayer


@export var server_address: LineEdit


func _on_back_pressed() -> void:
	get_parent().add_child(load(get_parent().title_screen_file).instantiate())
	queue_free()
	

func _on_join_server_pressed() -> void:
	$"../../Worlds".make_client(server_address.text)
	queue_free()
	

func _on_host_locally_pressed() -> void:
	$"../../Worlds".make_server("%s/New World" % $"../../Worlds".WORLDS_DIR, server_address.text)
	queue_free()
	

