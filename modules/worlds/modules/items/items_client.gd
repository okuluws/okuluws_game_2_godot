extends Node


const Client = preload("../worlds.gd").ClientWorld
@export var item_spawner: MultiplayerSpawner
@export var config: Node
@onready var client: Client = $"../"
var item_scene: PackedScene = load("item_client.tscn")


func _ready():
	item_spawner.spawn_function = func(_data):
		var new_item = item_scene.instantiate()
		new_item.client = client
		return new_item


