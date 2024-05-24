extends Node2D


var item_id
var target_position


func _physics_process(delta):
	position = position.lerp(target_position, 1 - pow(0.0002, delta))


func _on_timer_timeout():
	queue_free()
