extends AnimatedSprite2D


# REQUIRED
var client

var id
var stack


func _ready():
	sprite_frames = client.items.config.item_sprite_frames[id]
