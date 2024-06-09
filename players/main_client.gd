extends Node


@export var multiplayer_spawner: MultiplayerSpawner
@export var player_scene: PackedScene
@export var punch_scene : PackedScene
@export var fake_pickup_item_scene : PackedScene


func _ready():
	multiplayer_spawner.spawn_function = func(data):
		match data:
			"player":
				return player_scene.instantiate()
			"punch":
				return punch_scene.instantiate()
			"fake_pickup_item":
				return fake_pickup_item_scene.instantiate()

