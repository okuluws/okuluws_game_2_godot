extends Node


#@export var Overworld: Node
const World = preload("res://world/World.gd")


func get_persistent() -> Dictionary:
	return { }

static func load_persistent(_data: Dictionary, world: World) -> void:
	world.EntitySpawner.spawn({
		"id": "overworld"
	})
