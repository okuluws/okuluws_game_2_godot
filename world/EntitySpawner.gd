extends MultiplayerSpawner


@onready var World: Main.world_class = $"../"
@onready var Level := World.Level


func _spawn_function(data: Dictionary) -> Node:
	for k: String in data:
		assert(k in ["id", "properties"], "unknown argument >%s<" % k)
	
	var entity: Node2D = ((World.config.get("entities") as Dictionary).get(data["id"]) as PackedScene).instantiate()
	
	entity.set("entity_id", data["id"])
	
	if data.has("properties"):
		for k: String in data["properties"]:
			assert(k in entity)
			entity.set(k, data["properties"][k])
	
	return entity


func _enter_tree() -> void:
	spawn_function = _spawn_function
	

