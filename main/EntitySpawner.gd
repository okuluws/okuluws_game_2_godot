extends MultiplayerSpawner


@export var main_node: Node2D


const entity_scenes = {
	"punch": preload("res://player/punch.tscn"),
	"squareenemy": preload("res://squareenemy/squareenemy.tscn"),
	"player": preload("res://player/player.tscn"),
	"overworld": preload("res://overworld/overworld.tscn"),
	"item": preload("res://item/item.tscn"),
}


func _spawn_function(data: Dictionary):
	var entity: Node2D = entity_scenes[data["entity_name"]].instantiate()
	
	if data.has("set_main_node"):
		if data.set_main_node:
			entity.main_node = main_node
	
	
	if data.has("properties"):
		for k in data["properties"]:
			assert(k in entity)
			entity.set(k, data["properties"][k])
	
	return entity


func _enter_tree():
	spawn_function = _spawn_function












