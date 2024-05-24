extends Node


func _ready():
	$"MultiplayerSpawner".spawn_function = func(_data): return preload("res://overworld/overworld_client.tscn").instantiate()


