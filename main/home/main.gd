extends Node


# REQUIRED
@export var main: Node

@export var title_screen_scene: PackedScene
@export var server_selection_scene: PackedScene
@export var world_selection_scene: PackedScene
@export var game_options_scene: PackedScene
@export var server_display_scene: PackedScene
@export var world_edit_scene: PackedScene
@export var world_display_scene: PackedScene


func show_main_menu():
	add_child(title_screen_scene.instantiate())
	


