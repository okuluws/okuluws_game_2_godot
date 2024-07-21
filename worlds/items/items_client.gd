extends Node


const GameMain = preload("res://main.gd")
const source_directory = GameMain.Worlds.source_directory + "items/"
const Config = preload(source_directory + "items_config_client.gd")
@export var item_scene: PackedScene
@export var item_spawner: MultiplayerSpawner
@export var config: Config
var client: GameMain.Worlds.Client


func init(p_client: GameMain.Worlds.Client):
	client = p_client
	item_spawner.spawn_function = func(_data):
		var new_item = item_scene.instantiate()
		new_item.client = client
		return new_item
