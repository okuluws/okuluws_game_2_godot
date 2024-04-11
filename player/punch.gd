extends CharacterBody2D


@export var user_record_id: String
@export var timer: Timer
@export var auto_despawn: bool
@export var synced_position: Vector2


func _ready():
	if multiplayer.is_server():
		synced_position = position
		if auto_despawn:
			timer.start()

func _physics_process(_delta):
	if multiplayer.is_server():
		move_and_slide()
		synced_position = position
	else:
		position = Client.predict_client_position(position, synced_position, 14, 40)

func _on_timer_timeout():
	if multiplayer.is_server():
		set_physics_process(false)
		await get_tree().create_timer(0.04).timeout
		queue_free()

func _on_area_2d_body_entered(body: Node2D):
	if multiplayer.is_server():
		if body.name != str(user_record_id):
			if body.has_method("take_damage"):
				body.take_damage(3, user_record_id)
			
			#despawn
