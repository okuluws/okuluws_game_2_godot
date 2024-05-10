extends Node


const FunU = preload("res://globals/FuncU.gd")
const World = preload("res://world/World.gd")
@export var Player: Node


func get_persistent() -> Dictionary:
	#var player_config = FunU.BetterConfigFile.new("%s/players.cfg" % Player.World.WORLD_FOLDER)
	return {
		"position": Player.get("position"),
		"healthpoints_max": Player.get("healthpoints_max"),
		"healthpoints": Player.get("healthpoints"),
		"coins": Player.get("coins"),
		"player_type": Player.get("player_type"),
		#"peer_owner_network_address": (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(1).get_remote_address()
	}


static func load_persistent(_data: Dictionary, _world: World) -> void:
	#healthpoints_max = data.healthpoints_max
	#healthpoints = data.healthpoints
	pass
