extends Node


@export var Player: Node

const FunU = preload("res://globals/FuncU.gd")


func get_persistent():
	#var player_config = FunU.BetterConfigFile.new("%s/players.cfg" % Player.World.WORLD_FOLDER)
	return {
		"position": Player.position,
		"healthpoints_max": Player.healthpoints_max,
		"healthpoints": Player.healthpoints,
		"coins": Player.coins,
		"player_type": Player.player_type,
		#"peer_owner_network_address": (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(1).get_remote_address()
	}


static func load_persistent(_data, _World):
	#healthpoints_max = data.healthpoints_max
	#healthpoints = data.healthpoints
	pass
