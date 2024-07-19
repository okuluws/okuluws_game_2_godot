extends CharacterBody2D


## synced to client
var healthpoints: float
## synced to client
var healthpoints_max: float


func init(p_healthpoints: float, p_healthpoints_max: float) -> void:
	healthpoints = p_healthpoints
	healthpoints_max = p_healthpoints_max


func take_damage(damagepoints):
	healthpoints = clamp(healthpoints - damagepoints, 0.0, healthpoints_max)
	if healthpoints <= 0.0:
		queue_free()
		get_tree().create_timer(1).timeout.connect(func(): print("hooray"))
		return true
	return false
