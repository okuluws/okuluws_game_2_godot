extends Node


@export var pb: Node
@export var home: Node
@export var worlds: Node
@export var func_u: Node
var modules
#var options_file_path = "user://options.cfg"
#var options_file = ConfigFile.new()
#var options_hash


func _enter_tree():
	print("project version: %s" % ProjectSettings.get_setting_with_override("application/config/version"))
	modules = {
		"func_u": func_u,
		"pocketbase": pb,
		"worlds": worlds,
		"home": home,
	}


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
