extends Node


# REQUIRED
@export var client: Window

@export var item_spawner: MultiplayerSpawner
@export var config: Node
@export var item_scene: PackedScene


func _ready():
	item_spawner.spawn_function = func(_data):
		var new_item = item_scene.instantiate()
		new_item.client = client
		return new_item


