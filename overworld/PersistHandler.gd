extends Node


#@export var Overworld: Node


func get_persistent():
	return { }

static func load_persistent(_data, World):
	World.EntitySpawner.spawn({
		"id": "overworld"
	})
