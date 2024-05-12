extends MultiplayerSpawner


func _enter_tree():
	spawn_function = _spawn_function

func _spawn_function(data):
	return load(data).instantiate()
