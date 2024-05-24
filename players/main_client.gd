extends Node


func _ready():
	$"MultiplayerSpawner".spawn_function = func(data):
		match data:
			"player":
				return preload("res://players/player/player_client.tscn").instantiate()
			"punch":
				return preload("res://players/punch/punch_client.tscn").instantiate()
			"fake_pickup_item":
				return preload("res://players/fake_pickup_item/fake_pickup_item_client.tscn").instantiate()

