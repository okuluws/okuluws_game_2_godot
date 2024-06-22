extends Control


# REQUIRED
@export var home: Node

@export var ledit_server_name: LineEdit
@export var ledit_server_address: LineEdit
@onready var main = home.main


func _on_btn_add_pressed():
	var ip = ledit_server_address.text.get_slice(":", 0)
	var port = int(ledit_server_address.text.get_slice(":", 1))
	main.modules.worlds.add_remote_world(ledit_server_name.text, ip, port)
	home.show_menu("play_selection_screen")


func _on_btn_cancel_pressed():
	home.show_menu("play_selection_screen")


