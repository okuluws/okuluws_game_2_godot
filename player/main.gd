extends Node


const player_scene_filepath = "res://player/player.tscn"


func _ready():
	if $"../".name == "Server":
		$"../".finished_loading.connect(_on_finished_loading)
	

func _on_finished_loading():
	multiplayer.peer_connected.connect(_on_peer_connected)
	

func _on_peer_connected(peer_id: int):
	var new_player = load(player_scene_filepath).instantiate()
	new_player.name = str(peer_id)
	new_player.peer_owner = peer_id
	new_player.player_type = "square"
	$"../Level".add_child(new_player)
	


