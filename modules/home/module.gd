extends RefCounted


const Home = preload("main.gd")
const GameMain = preload("res://main.gd")
func _init(game_main: GameMain) -> void:
	var node: Home = preload("main.tscn").instantiate()
	node.init(game_main)
	game_main.add_child(node)
	game_main.modules["home"] = node
