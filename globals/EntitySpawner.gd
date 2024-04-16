extends MultiplayerSpawner


@export var main_node: Node2D


func _spawn_function(data: Dictionary):
	for k in data:
		assert(k in ["entity_name", "properties"], "unknown argument >%s<" % k)
	
	var entity: Node2D = Entities.data[data["entity_name"]].instantiate()
	
	if data.has("properties"):
		for k in data["properties"]:
			assert(k in entity)
			entity.set(k, data["properties"][k])
	
	return entity


func _enter_tree():
	spawn_function = _spawn_function
	spawn_path = World.get_path()












