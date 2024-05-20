extends AnimatedSprite2D


var item_id = null
var target_position = null


func _ready():
	sprite_frames = $"../../Items".config[item_id].sprite_frames
	play("default")
	


func _physics_process(delta):
	if not multiplayer.is_server(): return
	position = position.lerp(target_position, 1 - pow(0.0002, delta))


func _on_timer_timeout():
	if not multiplayer.is_server(): return
	queue_free()
