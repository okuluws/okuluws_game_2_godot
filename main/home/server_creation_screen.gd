extends Control


# REQUIRED
@export var home: Node

@export var ledit_world_name: LineEdit
@onready var main = home.main


func _on_btn_create_pressed():
	main.modules.worlds.create_server_world(ledit_world_name.text)
	home.show_play_selection_screen()
	queue_free()


func _on_btn_cancel_pressed():
	home.show_play_selection_screen()
	queue_free()

