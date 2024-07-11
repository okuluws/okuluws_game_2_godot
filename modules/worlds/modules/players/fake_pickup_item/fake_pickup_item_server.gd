extends Node2D


# REQUIRED
var target_position

var item_id


func _physics_process(delta):
	position = position.lerp(target_position, 1 - pow(0.0002, delta))


func _on_timer_timeout():
	queue_free()
