extends AnimatedSprite2D


const GameMain = preload("res://main.gd")
var players: GameMain.Worlds.Server.Players
var item_id


func init(p_players: GameMain.Worlds.Server.Players) -> void:
	players = p_players
	sprite_frames = players.client.items.config.item_sprite_frames[item_id]
