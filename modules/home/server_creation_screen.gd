extends Control


const Home = preload("main.gd")
@export var ledit_world_name: LineEdit
var home: Home
var game_main: Home.GameMain


func init(p_home: Home):
	home = p_home
	game_main = home.game_main


func _on_btn_create_pressed():
	var result = game_main.modules.worlds.create_server_world(ledit_world_name.text)
	game_main.modules.worlds.create_client_world(ledit_world_name.text, { "server_world_dir_path": result.ret })
	home.show_play_selection_screen()
	queue_free()


func _on_btn_cancel_pressed():
	home.show_play_selection_screen()
	queue_free()
