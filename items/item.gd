extends Area2D


var id = null
var stack = null:
	set(val):
		stack = val
		if stack <= 0:
			$"../../Items".despawn_item(self)


func _ready():
	$"AnimatedSprite2D".sprite_frames = $"../../Items".config[id].sprite_frames
	$"AnimatedSprite2D".play("default")
