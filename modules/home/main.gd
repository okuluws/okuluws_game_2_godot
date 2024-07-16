extends Node


const GameMain = preload("res://main.gd")
@export var scene_title_screen: PackedScene
@export var scene_play_selection_screen: PackedScene
@export var scene_server_creation_screen: PackedScene
@export var scene_client_creation_screen: PackedScene
@export var scene_server_config_screen: PackedScene
@export var scene_game_settings_screen: PackedScene
var game_main: GameMain


func init(p_game_main: GameMain):
	game_main = p_game_main


func _ready() -> void:
	show_title_screen()


func show_title_screen() -> void:
	var n = scene_title_screen.instantiate()
	n.init(self)
	add_child(n)


func show_play_selection_screen() -> void:
	var n = scene_play_selection_screen.instantiate()
	n.init(self)
	add_child(n)


func show_server_creation_screen() -> void:
	var n = scene_server_creation_screen.instantiate()
	n.init(self)
	add_child(n)


func show_client_creation_screen() -> void:
	var n = scene_client_creation_screen.instantiate()
	n.init(self)
	add_child(n)


func show_server_config_screen(world_dir_path: String) -> void:
	var n = scene_server_config_screen.instantiate()
	n.init(self)
	n.world_dir_path = world_dir_path
	add_child(n)


func show_game_settings_screen() -> void:
	var n = scene_game_settings_screen.instantiate()
	n.init(self)
	add_child(n)
