extends Control


const GameMain = preload("res://main.gd")
@export var ledit_server_name: LineEdit
@export var ledit_server_address: LineEdit
var home: GameMain.Home
var game_main: GameMain


func init(p_home: GameMain.Home):
	home = p_home
	game_main = home.game_main


func _on_btn_add_pressed():
	var ip = ledit_server_address.text.get_slice(":", 0)
	var port = int(ledit_server_address.text.get_slice(":", 1))
	game_main.worlds.create_client_world(ledit_server_name.text, { "ip": ip, "port": port })
	home.show_play_selection_screen()
	queue_free()


func _on_btn_cancel_pressed():
	home.show_play_selection_screen()
	queue_free()
