extends Node


func _ready():
	if multiplayer.is_server():
		$"../../".connect("finished_loading", func(): $"../../MultiplayerSpawner".spawn("res://overworld/overworld.tscn"))
