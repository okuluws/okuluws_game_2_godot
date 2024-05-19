extends Node


const player_scene_filepath = "res://player/player.tscn"

var players = {}


func _ready():
	if $"../".name == "Server":
		$"../".finished_loading.connect(_on_server_finished_loading)
	

func _on_server_finished_loading():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(peer_id: int):
	var new_player = load(player_scene_filepath).instantiate()
	new_player.name = str(peer_id)
	new_player.username = $"../".peer_users[peer_id].username
	new_player.peer_owner = peer_id
	new_player.player_type = "square"
	$"../Level".add_child(new_player)
	players[peer_id] = new_player

func _on_peer_disconnected(peer_id: int):
	players[peer_id].queue_free()
	players.erase(peer_id)
