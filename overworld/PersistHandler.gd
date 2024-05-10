extends Node


#@export var Overworld: Node


func get_persistent() -> Dictionary:
	return { }

static func load_persistent(_data: Dictionary, World: Main.world_class) -> void:
	World.EntitySpawner.spawn({
		"id": "overworld"
	})
