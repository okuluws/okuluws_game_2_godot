extends Area2D


@export var item: Node
var already_picked_up = false


func _on_body_entered(body: Node2D):
	if not multiplayer.is_server() or already_picked_up:
		return
	
	if body.has_method("pickup_item"):
		already_picked_up = true
		body.pickup_item(item.data)
		queue_free()
