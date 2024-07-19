extends Node2D



var target_position: Vector2
var item_id


func init(p_target_position: Vector2) -> void:
	target_position = p_target_position


func _physics_process(delta):
	position = position.lerp(target_position, 1 - pow(0.0002, delta))


func _on_timer_timeout():
	queue_free()
