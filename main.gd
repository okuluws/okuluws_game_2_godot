extends Node


class Modules extends RefCounted:
	const FuncU = preload("modules/func_u/func_u.gd")
	var func_u: FuncU
	const Pocketbase = preload("modules/pocketbase/pocketbase.gd")
	var pocketbase: Pocketbase
	const Worlds = preload("modules/worlds/worlds.gd")
	var worlds: Worlds
	const Home = preload("modules/home/main.gd")
	var home: Home
var modules: Modules = Modules.new()


func _ready():
	for dirname in DirAccess.get_directories_at("res://modules/"):
		var dirpath = "res://modules/%s/" % dirname
		var cfg = ConfigFile.new()
		if cfg.load(dirpath.path_join("module.cfg")) != OK:
			push_error("coudln't find module.cfg for module at %s" % dirpath)
			continue
		var module_id = cfg.get_value("", "id")
		if cfg.has_section_key("", "scene"):
			var node = load(dirpath.path_join(cfg.get_value("", "scene"))).instantiate()
			add_child(node)
			modules[module_id] = { "instance": node, "type": node.get_script() }
		elif cfg.has_section_key("", "script"):
			var script = load(dirpath.path_join(cfg.get_value("", "script")))
			modules[module_id] = { "instance": script.new(), "type": script }
	
	print("project version: %s" % ProjectSettings.get_setting_with_override("application/config/version"))



func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


#func _process(_delta):
	#stretch_auto()
#
#
#
#
#func load_config():
	#if options_file.load(options_file_path) != OK:
		#push_error()
		#return
	#apply_changes()
	#options_hash = options_file.encode_to_text().hash()
#
#
#func apply_changes():
	#get_tree().root.content_scale_factor = get_content_scale_factor()
#
#
#func save_config():
	#if options_file.save(options_file_path) != OK:
		#push_error()
		#return
	#options_hash = options_file.encode_to_text().hash()
#
#
#func reset_config():
	#options_file.clear()
	#set_content_scale_factor(1.0)
	#set_virtual_joystick(OS.has_feature("mobile"))
	#apply_changes()
	#save_config()
#
#
#func config_has_changes():
	#return options_file.encode_to_text().hash() != options_hash
#
#
#func set_content_scale_factor(val):
	#options_file.set_value("video", "content_scale_factor", val)
#
#
#func get_content_scale_factor():
	#return options_file.get_value("video", "content_scale_factor")
#
#
#func set_virtual_joystick(val):
	#options_file.set_value("gameplay", "virtual_joystick", val)
#
#
#func get_virtual_joystick():
	#return options_file.get_value("gameplay", "virtual_joystick")
#
