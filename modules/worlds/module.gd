extends RefCounted


const GameMain = preload("res://main.gd")
func _init(game_main: GameMain) -> void:
	var node = preload("worlds.tscn").instantiate()
	game_main.add_child(node)
	game_main.modules["worlds"] = node
