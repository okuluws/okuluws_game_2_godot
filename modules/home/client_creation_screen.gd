extends Control


const Home = preload("main.gd")
@export var ledit_server_name: LineEdit
@export var ledit_server_address: LineEdit
var home: Home
var game_main: Home.GameMain


func init(p_home: Home):
	home = p_home
	game_main = home.game_main


func _on_btn_add_pressed():
	var ip = ledit_server_address.text.get_slice(":", 0)
	var port = int(ledit_server_address.text.get_slice(":", 1))
	game_main.modules.worlds.create_client_world(ledit_server_name.text, { "ip": ip, "port": port })
	home.show_play_selection_screen()
	queue_free()


func _on_btn_cancel_pressed():
	home.show_play_selection_screen()
	queue_free()
