func _init(_main: Main) -> void:
	if not DirAccess.dir_exists_absolute("user://worlds"):
		DirAccess.make_dir_absolute("user://worlds")
