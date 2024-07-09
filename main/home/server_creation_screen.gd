extends Control


const Home = preload("main.gd")
const GameMain = Home.GameMain

# REQUIRED
var home: Home

@export var ledit_world_name: LineEdit
var main: GameMain


func _enter_tree():
	main = home.main


func _on_btn_create_pressed():
	var result = main.modules.worlds.create_server_world(ledit_world_name.text)
	main.modules.worlds.create_client_world(ledit_world_name.text, { "server_world_dir_path": result.ret })
	home.show_play_selection_screen()
	queue_free()


func _on_btn_cancel_pressed():
	home.show_play_selection_screen()
	queue_free()

