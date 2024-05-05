extends CharacterBody2D


@export var timer: Timer
var peer_owner: int
var entity_id: String


func _ready():
	if multiplayer.is_server():
		timer.start()

func _physics_process(_delta):
	move_and_slide()

func _on_timer_timeout():
	if multiplayer.is_server():
		set_physics_process(false)
		await get_tree().create_timer(0.04).timeout
		queue_free()

func _on_area_2d_body_entered(body: Node2D):
	if multiplayer.is_server():
		if not ("peer_owner" in body and body.peer_owner != peer_owner) and body.has_method("take_damage"):
			body.take_damage(3, [peer_owner])
			
			#despawn
