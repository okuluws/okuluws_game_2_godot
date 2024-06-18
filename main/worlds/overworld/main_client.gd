extends Node


@export var overworld_scene: PackedScene
@export var squareenemy_scene: PackedScene
@export var multiplayer_spawner: MultiplayerSpawner


func _ready():
	multiplayer_spawner.spawn_function = func(data):
		match data:
			"overworld":
				return overworld_scene.instantiate()
			"squareenemy":
				return squareenemy_scene.instantiate()


