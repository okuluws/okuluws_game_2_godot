extends Node


# REQUIRED
@export var client: Window

@export var multiplayer_spawner: MultiplayerSpawner
@export var player_scene: PackedScene
@export var punch_scene : PackedScene
@export var fake_pickup_item_scene : PackedScene
@export var player_ui_scene: PackedScene
@export var item_slot_scene: PackedScene
@export var config: Node


func _ready():
	multiplayer_spawner.spawn_function = func(data):
		match data:
			"player":
				var new_player = player_scene.instantiate()
				new_player.players = self
				return new_player
			"punch":
				return punch_scene.instantiate()
			"fake_pickup_item":
				var new_fake_pickup_item = fake_pickup_item_scene.instantiate()
				new_fake_pickup_item.players = self
				return new_fake_pickup_item

