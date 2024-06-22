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


# TODO: delete entire folder with files at once, to make it faster and not spam the trash, dis may be platform specifique
func trash_recursive(path: String):
	if not path.begins_with("user://"):
		return "are you fucking mental?"
	
	for f in DirAccess.get_files_at(path):
		#print("trashing " + path.path_join(f))
		if OS.move_to_trash(ProjectSettings.globalize_path(path.path_join(f))) != OK:
			return "couldn't trash file %" % ProjectSettings.globalize_path(path.path_join(f))
	
	for d in DirAccess.get_directories_at(path):
		#print("trashing " + path.path_join(d))
		var err = trash_recursive(path.path_join(d))
		if err != null:
			return err
		if OS.move_to_trash(ProjectSettings.globalize_path(path.path_join(d))) != OK:
			return "couldn't trash dir %" % ProjectSettings.globalize_path(path.path_join(d))
	
	if OS.move_to_trash(ProjectSettings.globalize_path(path)) != OK:
		return "couldn't trash dir %" % ProjectSettings.globalize_path(path)
	
	return null


func unreachable(message: String = ""):
	push_error(message)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
