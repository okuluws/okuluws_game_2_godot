extends Node


const player_scene_filepath = "res://player/player.tscn"


func _ready():
	if $"../".name == "Server":
		$"../".finished_loading.connect(_on_finished_loading)
	

func _on_finished_loading():
	multiplayer.peer_connected.connect(_on_peer_connected)
	

func _on_peer_connected(peer_id: int):
	var peer_ip = multiplayer.multiplayer_peer.get_peer(peer_id).get_remote_address()
	if peer_ip == "127.0.0.1":
		var new_player = load(player_scene_filepath).instantiate()
		new_player.name = str(peer_id)
		new_player.peer_owner = peer_id
		new_player.player_type = "square"
		$"../Level".add_child(new_player)
	else:
		prints("hello peer", peer_id, "from", peer_ip, "please validate your existence.")


