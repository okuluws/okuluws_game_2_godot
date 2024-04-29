extends Node



## ConfigFile but with syncing and saved filepath
class BetterConfig:
	var filepath: String
	var config_file: ConfigFile
	var subscriptions = {}
	
	func _init(filepath_: String) -> void:
		config_file = ConfigFile.new()
		filepath = filepath_
		if FileAccess.file_exists(filepath):
			config_file.load(filepath)
		else:
			config_file.save(filepath)
	
	func set_value(section: String, key: String, val) -> void:
		config_file.set_value(section, key, val)
		config_file.save(filepath)
		if subscriptions.has("%s/%s" % [section, key]):
			subscriptions["%s/%s" % [section, key]].call(get_value(section, key))
	
	func get_value(section: String, key: String):
		return config_file.get_value(section, key)
	
	func compare_value(section: String, key: String, val) -> bool:
		return config_file.get_value(section, key) == val
	
	func has_section_key(section: String, key: String) -> bool:
		return config_file.has_section_key(section, key)
	
	func subscribe(section: String, key: String, callback: Callable) -> void:
		subscriptions["%s/%s" % [section, key]] = callback
		
		if has_section_key(section, key):
			callback.call(get_value(section, key))
	
	
