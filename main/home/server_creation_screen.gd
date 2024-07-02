extends Control


# REQUIRED
@export var home: Node

@export var ledit_world_name: LineEdit
@onready var main = home.main


func _on_btn_create_pressed():
	var result = main.modules.worlds.create_server_world(ledit_world_name.text)
	main.modules.worlds.create_client_world(ledit_world_name.text, { "server_world_dir_path": result.ret })
	home.show_play_selection_screen()
	queue_free()


func _on_btn_cancel_pressed():
	home.show_play_selection_screen()
	queue_free()

