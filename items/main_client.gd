extends Node


func _ready():
	$"MultiplayerSpawner".spawn_function = func(_data): return preload("res://items/item_client.tscn").instantiate()


