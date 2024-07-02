extends Node


# REQUIRED
@export var main: Node

@export var scene_title_screen: PackedScene
@export var scene_play_selection_screen: PackedScene
@export var scene_server_creation_screen: PackedScene
@export var scene_client_creation_screen: PackedScene
@export var scene_server_config_screen: PackedScene


func _ready():
	show_title_screen()


func show_title_screen():
	var n = scene_title_screen.instantiate()
	n.home = self
	add_child(n)


func show_play_selection_screen():
	var n = scene_play_selection_screen.instantiate()
	n.home = self
	add_child(n)


func show_server_creation_screen():
	var n = scene_server_creation_screen.instantiate()
	n.home = self
	add_child(n)


func show_client_creation_screen():
	var n = scene_client_creation_screen.instantiate()
	n.home = self
	add_child(n)


func show_server_config_screen(world_dir_path: String):
	var n = scene_server_config_screen.instantiate()
	n.home = self
	n.world_dir_path = world_dir_path
	add_child(n)
	
	


