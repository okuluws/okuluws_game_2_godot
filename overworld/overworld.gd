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
			"entity_name": "squareenemy_fragment",
			"properties": {
				"position": Vector2(500, 500),
				"data": { "name": "squareenemy_fragment" },
			},
		})
