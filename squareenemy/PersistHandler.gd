extends Node


@export var Squareenemy: Node


func get_persistent() -> Dictionary:
	return {
		"position": Squareenemy.get("position"),
		"healthpoints_max": Squareenemy.get("healthpoints_max"),
		"healthpoints": Squareenemy.get("healthpoints"),
	}

static func load_persistent(data: Dictionary, World: Main.world_class) -> void:
	var squareenemy := World.EntitySpawner.spawn({
		"id": "squareenemy",
		"properties": { "position": data.position }
	})
	squareenemy.set("healthpoints_max", data.healthpoints_max)
	squareenemy.set("healthpoints", data.healthpoints)
	# Why not set these in spawn()? - Both is possible but you should only do that if really needed like for position which would be set to zero before sync and that could mess things up client side


func save() -> void: pass
func startup_load() -> void: pass

