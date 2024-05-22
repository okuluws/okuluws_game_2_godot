extends CharacterBody2D


@export var PersistHandler: Node

const World = preload("res://world/World.gd")
@onready var world: World = get_viewport().get_child(0)
@onready var EntitySpawner: MultiplayerSpawner = world.EntitySpawner

var healthpoints_max: int = 20
var healthpoints: int = 20
var already_dead: bool = false
var entity_id: String


func _process(_delta: float) -> void:
	if float(healthpoints) / healthpoints_max > 0.5:
		(%Health as RichTextLabel).text = "[center]Squareenemy [color=green]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	elif float(healthpoints) / healthpoints_max > 0.2:
		(%Health as RichTextLabel).text = "[center]Squareenemy [color=orange]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	else:
		(%Health as RichTextLabel).text = "[center]Squareenemy [color=red]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]

func take_damage(damagepoints: int, rewards_peer_: int) -> void:
	assert(multiplayer.is_server())
	healthpoints = clampi(healthpoints - damagepoints, 0, healthpoints_max)
	if healthpoints <= 0 and not already_dead:
		already_dead = true
		remove_from_group("Persist")
		
		for rewards_peer in rewards_peer_:
			# TODO: award coins
			pass
		await get_tree().create_timer(1).timeout
		EntitySpawner.spawn({
			"id": "squareenemy",
			"properties": {
				"position": Vector2(300, 500)
			},
		})
		queue_free()
	




