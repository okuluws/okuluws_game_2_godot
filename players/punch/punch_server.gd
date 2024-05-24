extends CharacterBody2D


@onready var despawn_timer = $"Timer"
var peer_owner


func _physics_process(_delta):
	move_and_slide()


func _on_timer_timeout():
	set_physics_process(false)
	await get_tree().create_timer(0.04).timeout
	queue_free()


func _on_area_2d_body_entered(body):
	if not ("player_common" in body and body.peer_owner != peer_owner) and body.has_method("take_damage"):
		body.take_damage(3, peer_owner)
		
		#despawn


