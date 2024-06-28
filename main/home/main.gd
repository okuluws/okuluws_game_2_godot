extends Node


# REQUIRED
@export var main: Node

@export var scene_title_screen: PackedScene
@export var scene_play_selection_screen: PackedScene
@export var scene_create_world_screen: PackedScene
@export var scene_add_server_screen: PackedScene
@export var scene_local_world_config_screen: PackedScene


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


func show_create_world_screen():
	var n = scene_create_world_screen.instantiate()
	n.home = self
	add_child(n)


func show_add_server_screen():
	var n = scene_add_server_screen.instantiate()
	n.home = self
	add_child(n)


func show_local_world_config_screen(world_dir_path: String):
	var n = scene_local_world_config_screen.instantiate()
	n.home = self
	n.world_dir_path = world_dir_path
	add_child(n)
	
	


