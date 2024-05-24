extends Node


func _ready():
	$"MultiplayerSpawner".spawn_function = _spawn_function


func _spawn_function(_data):
	var new_item = preload("res://items/item_client.tscn").instantiate()
	return new_item

