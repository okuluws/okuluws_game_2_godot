extends MultiplayerSpawner


@export var main_node: Node2D

const entity_scenes = {
	"punch": preload("res://player/punch.tscn"),
	"squareenemy": preload("res://squareenemy/squareenemy.tscn"),
	"player": preload("res://player/player.tscn"),
	"overworld": preload("res://overworld/overworld.tscn"),
}


func _enter_tree():
	spawn_function = _spawn_entity

func _spawn_entity(data: Dictionary):
	var entity: Node2D = entity_scenes[data["entity"]].instantiate()
	
	# EVERYTHING should belong to server(peer_id: 1) which is the default anyways
	#if data.has("authority"):
	#	entity.set_multiplayer_authority(data["authority"])
	
	
	if data.has("set_main_node"):
		if data["set_main_node"]:
			assert("main_node" in entity)
			entity.main_node = main_node
	
	# maybe i should do this instead
	#if "main_node" in entity:
	#	entity.main_node = main_node
	
	if data.has("properties"):
		for k in data["properties"]:
			assert(k in entity)
			entity.set(k, data["properties"][k])
	
	return entity
