extends CharacterBody2D


# REQUIRED
var peer_owner


func _physics_process(_delta):
	move_and_slide()


func _on_timer_timeout():
	set_physics_process(false)
	await get_tree().create_timer(0.04).timeout
	queue_free()


func _on_area_2d_body_entered(_body):
	#if body.has_method("take_damage"):
		#body.take_damage(3, peer_owner)
		
	pass


