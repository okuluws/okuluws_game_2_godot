extends Node


var _config = ConfigFile.new()
var _config_hash


func _ready():
	if not FileAccess.file_exists("user://options.cfg"): reset_config()
	load_config()
	#print(IP.get_local_interfaces())
	#var k = Crypto.new().generate_rsa(256)
	#print(k.save_to_string())
	#print(k.save_to_string(true))
	
	


#func _process(_delta):
	#stretch_auto()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		print("closing game")


func load_config():
	if _config.load("user://options.cfg") != OK: push_error(); return
	apply_changes()
	_config_hash = _config.encode_to_text().hash()


func apply_changes():
	get_tree().root.content_scale_factor = get_content_scale_factor()


func save_config():
	if _config.save("user://options.cfg") != OK: push_error(); return
	_config_hash = _config.encode_to_text().hash()


func reset_config():
	_config.clear()
	set_content_scale_factor(3.0 if OS.has_feature("mobile") else 2.0)
	set_virtual_joystick(OS.has_feature("mobile"))
	apply_changes()
	save_config()


func config_has_changes():
	return _config.encode_to_text().hash() != _config_hash


func set_content_scale_factor(val):
	_config.set_value("video", "content_scale_factor", val)


func get_content_scale_factor():
	return _config.get_value("video", "content_scale_factor")


func set_virtual_joystick(val):
	_config.set_value("gameplay", "virtual_joystick", val)


func get_virtual_joystick():
	return _config.get_value("gameplay", "virtual_joystick")



