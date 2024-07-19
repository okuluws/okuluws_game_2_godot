extends AnimatedSprite2D


const GameMain = preload("res://main.gd")
var client: GameMain.Worlds.Client
var id
var stack


func init(p_client: GameMain.Worlds.Client):
	client = p_client
	sprite_frames = client.items.config.item_sprite_frames[id]
