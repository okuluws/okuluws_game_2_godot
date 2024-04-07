extends Area2D


@export var main_node: Node
@export var texture_animator: AnimationPlayer


func _on_body_entered(body: Node2D):
	if body.has_method("pickup_item"):
		body.pickup_item($".")
		queue_free()
