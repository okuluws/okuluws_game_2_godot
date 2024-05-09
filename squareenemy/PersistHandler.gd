extends Node


@export var Squareenemy: Node


func get_persistent():
	return {
		"position": Squareenemy.position,
		"healthpoints_max": Squareenemy.healthpoints_max,
		"healthpoints": Squareenemy.healthpoints,
	}

static func load_persistent(data, World):
	var squareenemy = World.EntitySpawner.spawn({
		"id": "squareenemy",
		"properties": { "position": data.position }
	})
	squareenemy.healthpoints_max = data.healthpoints_max
	squareenemy.healthpoints = data.healthpoints
	# Why not set these in spawn()? - Both is possible but you should only do that if really needed like for position which would be set to zero before sync and that could mess things up client side


func save(): pass
func startup_load(): pass

