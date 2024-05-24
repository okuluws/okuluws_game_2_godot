extends AnimatedSprite2D


@onready var items_handler = $"../../Items"
var item_id = null
var target_position = null


func _ready():
	sprite_frames = items_handler.config[item_id].sprite_frames
	


func _physics_process(delta):
	if not multiplayer.is_server(): return
	position = position.lerp(target_position, 1 - pow(0.0002, delta))


func _on_timer_timeout():
	if not multiplayer.is_server(): return
	queue_free()
