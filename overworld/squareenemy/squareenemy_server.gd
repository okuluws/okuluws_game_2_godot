extends CharacterBody2D


@onready var multiplayer_spawner
var healthpoints = 20.0
var healthpoints_max = 20.0


func take_damage(damagepoints):
	healthpoints = clamp(healthpoints - damagepoints, 0.0, healthpoints_max)
	if healthpoints <= 0.0:
		queue_free()
		get_tree().create_timer(1).timeout.connect(func(): print("hooray"))
		return true
	return false

