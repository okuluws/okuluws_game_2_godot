extends Node2D


@export var main_node: Node2D


func _ready():
	if multiplayer.is_server():
		main_node.entity_spawner.spawn({
			"entity_name": "squareenemy",
			"set_main_node": true,
			"properties": {
				"position": Vector2(300, 500)
			},
		})
		
		main_node.entity_spawner.spawn({
			"entity_name": "item",
			"set_main_node": true,
			"properties": {
				"position": Vector2(500, 500),
				"current_texture": "squareenemy_fragment",
			},
		})
