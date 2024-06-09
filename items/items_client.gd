extends Node


# REQUIRED
@export var client: SubViewport

@onready var level = client.level
@export var item_spawner: MultiplayerSpawner
@export var config: Node
@export var item_scene: PackedScene


func _ready():
	item_spawner.spawn_path = level.get_path()
	item_spawner.spawn_function = func(_data):
		var new_item = item_scene.instantiate()
		new_item.client = client
		return new_item


