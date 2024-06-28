extends AnimatedSprite2D


# REQUIRED
var players

var item_id


func _ready():
	sprite_frames = players.client.modules.items.config.item_sprite_frames[item_id]
