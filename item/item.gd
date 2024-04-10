extends Area2D


@export var main_node: Node
@export var item_data: Dictionary

var already_picked_up = false

func _process(_delta):
	$"TextureAnimator".play(item_data.name)

func _on_body_entered(body: Node2D):
	if not multiplayer.is_server() or already_picked_up:
		return
	
	if body.has_method("pickup_item"):
		already_picked_up = true
		body.pickup_item(item_data)
		queue_free()
