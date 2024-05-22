extends Area2D


var id = null
var stack = null


func _ready():
	$"AnimatedSprite2D".sprite_frames = $"../../Items".config[id].sprite_frames
	$"AnimatedSprite2D".play("default")


func despawn():
	$"../../Items".despawn_item(self)
