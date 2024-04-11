extends MultiplayerSpawner


@export var main_node: Node2D


func _spawn_function(data: Dictionary):
	var entity: Node2D = Entities.data[data["entity_name"]].instantiate()
	
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












