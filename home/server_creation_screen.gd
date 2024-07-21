extends Control


const GameMain = preload("res://main.gd")
@export var ledit_world_name: LineEdit
var home: GameMain.Home
var game_main: GameMain


func init(p_home: GameMain.Home) -> void:
	home = p_home
	game_main = home.game_main


func _on_btn_create_pressed():
	var result = game_main.worlds.create_server_world(ledit_world_name.text)
	game_main.worlds.create_client_world(ledit_world_name.text, { "server_world_directory": result })
	home.show_play_selection_screen()
	queue_free()


func _on_btn_cancel_pressed():
	home.show_play_selection_screen()
	queue_free()
