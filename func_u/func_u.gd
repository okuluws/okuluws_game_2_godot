# NOTE: waiting for nullable static types so errors can become a nullable string instead of variant

extends Node


func panic(message: String):
	push_error("PANIC PANIC PANIC PANIC:\n%s" % message)
	get_tree().quit(1)


func create_directory(path: String) -> void:
	if DirAccess.make_dir_absolute(path) != OK:
		panic("couldn't create directory %s" % path)


func create_file(path: String) -> void:
	if FileAccess.open(path, FileAccess.WRITE) == null:
		panic("couldn't create file %s" % path)


func copy_file(source_path: String, target_path: String) -> void:
	if DirAccess.copy_absolute(source_path, target_path) != OK:
		panic("couldn't copy file %s to %s" % [source_path, target_path])


func save_config_file(o: ConfigFile, path: String) -> void:
	if o.save(path) != OK:
		panic("couldn't save config file %s" % path)


func load_config_file(o: ConfigFile, path: String) -> void:
	if o.load(path) != OK:
		panic("couldn't load config file %s" % path)


# TODO: handle errors
func delete_recursively(path: String) -> Variant:
	if not path.begins_with("user://"):
		return "are you fucking insane"
	
	match OS.get_name(): # TODO: support more platforms natively
		"Windows":
			OS.execute("CMD.exe", ["/C", 'rd /s /q "%s"' % ProjectSettings.globalize_path(path)])
		_:
			_delete_recursively_fallback(path)
	return null


# TODO: handle errors
func _delete_recursively_fallback(path: String) -> void:
	for dir in DirAccess.get_directories_at(path):
		_delete_recursively_fallback(path.path_join(dir))
	
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


class OptionalString extends RefCounted:
	var val: String
	func _init(p_val: String) -> void:
		val = p_val


class OptionalDictionary extends RefCounted:
	var val: Dictionary
	func _init(p_val: Dictionary) -> void:
		val = p_val
