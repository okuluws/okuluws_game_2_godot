extends AnimatedSprite2D


# REQUIRED
var client: Client

const Client = preload("../worlds.gd").ClientWorld
var id
var stack


func _ready():
	sprite_frames = client.modules.items.config.item_sprite_frames[id]
