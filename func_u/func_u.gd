# NOTE: waiting for nullable static types so errors can become a nullable string instead of variant

extends Node


func DirAccess_make_dir_absolute(path: String) -> Variant:
	if DirAccess.make_dir_absolute(path) != OK:
		return "couldn't make dir %s" % path
	return null


func ConfigFile_save(o: ConfigFile, path: String) -> Variant:
	if o.save(path) != OK:
		return "couldn't save config file %s" % path
	return null


func ConfigFile_load(o: ConfigFile, path: String) -> Variant:
	if o.load(path) != OK:
		return "couldn't load config file %s" % path
	return null


func ConfigFile_copy(o: ConfigFile, other: ConfigFile) -> Variant:
	if o.parse(other.encode_to_text()) != OK:
		return "how?"
	return null


func unreachable(message: String = "") -> void:
	push_error("reached unreachable code, message:\n%s" % message)
	get_tree().quit()


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
func _delete_recursively_fallback(path: String):
	for dir in DirAccess.get_directories_at(path):
		_delete_recursively_fallback(path.path_join(dir))
	
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)
