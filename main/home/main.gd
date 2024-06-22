extends Node


# REQUIRED
@export var main: Node

@export var scene_title_screen: PackedScene
@export var scene_play_selection_screen: PackedScene
@export var scene_create_world_screen: PackedScene
@export var scene_add_server_screen: PackedScene


@onready var scenes_menu = {
	"title_screen": scene_title_screen,
	"play_selection_screen": scene_play_selection_screen,
	"create_world_screen": scene_create_world_screen,
	"add_server_screen": scene_add_server_screen,
}
var node_current_menu


func _ready():
	show_main_menu()


func show_menu(id):
	var new_menu = scenes_menu[id].instantiate()
	new_menu.home = self
	if node_current_menu != null:
		node_current_menu.queue_free()
	node_current_menu = new_menu
	add_child(new_menu)


func show_main_menu():
	show_menu("title_screen")
