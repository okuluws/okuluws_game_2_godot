extends Control


# REQUIRED
@export var home: Node

@export var ledit_world_name: LineEdit
@onready var main = home.main


func _on_btn_create_pressed():
	main.modules.worlds.create_world(ledit_world_name.text)
	home.show_menu("play_selection_screen")


func _on_btn_cancel_pressed():
	home.show_menu("play_selection_screen")

