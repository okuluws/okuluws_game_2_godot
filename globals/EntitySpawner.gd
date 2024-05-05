extends MultiplayerSpawner


@onready var World = $"../"
@onready var Level = $"../Level"


func _spawn_function(data: Dictionary):
	for k in data:
		assert(k in ["id", "properties"], "unknown argument >%s<" % k)
	
	var entity: Node2D = World.config.entities[data["id"]].instantiate()
	
	entity.entity_id = data["id"]
	
	if data.has("properties"):
		for k in data["properties"]:
			assert(k in entity)
			entity.set(k, data["properties"][k])
	
	return entity


func _enter_tree():
	spawn_function = _spawn_function
	

