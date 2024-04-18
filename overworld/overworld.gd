extends Node2D


func _ready():
	if multiplayer.is_server():
		EntitySpawner.spawn({
			"entity_name": "squareenemy",
			"properties": {
				"position": Vector2(300, 500)
			},
		})
		
		EntitySpawner.spawn({
			"entity_name": "square_fragment",
			"properties": {
				"position": Vector2(500, 500),
			},
		})
		
		EntitySpawner.spawn({
			"entity_name": "widesquare_fragment",
			"properties": {
				"position": Vector2(700, 500),
				"data": { "name": "widesquare_fragment" },
			},
		})
		
		EntitySpawner.spawn({
			"entity_name": "triangle_fragment",
			"properties": {
				"position": Vector2(900, 500),
				"data": { "name": "triangle_fragment" },
			},
		})
