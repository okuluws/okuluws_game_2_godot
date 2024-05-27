extends Node


func _ready():
	$"MultiplayerSpawner".spawn_function = func(data):
		match data:
			"overworld":
				return preload("res://overworld/overworld_client.tscn").instantiate()
			"squareenemy":
				return preload("res://overworld/squareenemy/squareenemy_client.tscn").instantiate()


