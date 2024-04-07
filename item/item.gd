extends Area2D


@export var main_node: Node
@export var current_texture: String

func _process(_delta):
	$"TextureAnimator".play(current_texture)

func _on_body_entered(body: Node2D):
	if not multiplayer.is_server():
		return
	
	if body.has_method("pickup_item"):
		body.pickup_item($".")
		queue_free()
