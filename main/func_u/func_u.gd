extends Node


func DirAccess_make_dir_absolute(path: String):
	if DirAccess.make_dir_absolute(path) != OK:
		return "couldn't make dir %s" % path
	return null


func ConfigFile_save(o: ConfigFile, path: String):
	if o.save(path) != OK:
		return "couldn't save config file %s" % path
	return null


func ConfigFile_load(o: ConfigFile, path: String):
	if o.load(path) != OK:
		return "couldn't load config file %s" % path
	return null


func ConfigFile_copy(o: ConfigFile, other: ConfigFile):
	if o.parse(other.encode_to_text()) != OK:
		return "how?"
	return null


func unreachable(message: String = ""):
	push_error("reached unreachable code")
	if message != "":
		push_error("custom message: %s" % message)
	get_tree().quit()


func delete_recursively(path: String):
	if not path.begins_with("user://"):
		return "are you fucking insane"
	
	match OS.get_name(): # TODO: support more platforms natively
		"Windows":
			OS.execute("CMD.exe", ["/C", 'rd /s /q "%s"' % ProjectSettings.globalize_path(path)])
		_:
			_delete_recursively_fallback(path)


func _delete_recursively_fallback(path: String):
	for dir in DirAccess.get_directories_at(path):
		_delete_recursively_fallback(path.path_join(dir))
	
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)

