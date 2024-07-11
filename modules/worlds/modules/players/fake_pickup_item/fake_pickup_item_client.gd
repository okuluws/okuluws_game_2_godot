extends AnimatedSprite2D


# REQUIRED
var players: Players

const Players = preload("../main_client.gd")
var item_id


func _ready():
	sprite_frames = players.client.modules.items.config.item_sprite_frames[item_id]
