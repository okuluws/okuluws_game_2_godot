extends Node


const GameMain = preload("res://main.gd")
const source_directory = GameMain.Worlds.source_directory + "players/"
const Player = preload(source_directory + "player/player_client.gd")
@export var multiplayer_spawner: MultiplayerSpawner
@export var player_scene: PackedScene
@export var punch_scene : PackedScene
@export var fake_pickup_item_scene : PackedScene
@export var player_ui_scene: PackedScene
@export var item_slot_scene: PackedScene
@export var config: Node
var client: GameMain.Worlds.Client


func init(p_client: GameMain.Worlds.Client) -> void:
	client = p_client
	multiplayer_spawner.spawn_function = func(data):
		match data:
			"player":
				var new_player = player_scene.instantiate()
				new_player.players = self
				return new_player
			"punch":
				return punch_scene.instantiate()
			"fake_pickup_item":
				var new_fake_pickup_item = fake_pickup_item_scene.instantiate()
				new_fake_pickup_item.players = self
				return new_fake_pickup_item
