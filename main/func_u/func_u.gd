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


func unreachable(message: String = ""):
	push_error(message)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
