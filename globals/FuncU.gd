extends Node


## self explanatory
class ConfigFileSyncedValue:
	var filepath: String
	var section: String
	var key: String
	var value:
		get:
			var c = ConfigFile.new()
			c.load(filepath)
			return c.get_value(section, key)
		
		set(_value):
			var c = ConfigFile.new()
			c.load(filepath)
			c.set_value(section, key, _value)
			c.save(filepath)

	func _init(_filepath: String, _section: String, _key: String, _value) -> void:
		var c = ConfigFile.new()
		if not FileAccess.file_exists(_filepath):
			c.save(_filepath)
		
		c.load(_filepath)
		if not c.has_section_key(_section, _key):
			c.set_value(_section, _key, _value)
			c.save(_filepath)
		
		filepath = _filepath
		section = _section
		key = _key


func string_erase(string: String, i_start: int, i_stop: int = -1) -> String:
	if i_stop == -1:
		return string.left(i_start)
	return string.erase(i_start, i_stop - i_start)


func remove_enclosed_string(string: String, start_delimator: String, stop_delimator: String) -> String:
	while string.contains(start_delimator):
		string = string_erase(string, string.find(start_delimator), string.find(stop_delimator, string.find(start_delimator) + 1) + 1)
	return string


func map_dict(dict: Dictionary, callable: Callable) -> Dictionary:
	var result = {}
	var _dict = dict.duplicate(true)
	for k in _dict:
		var _val = callable.call(k, _dict[k])
		if _val != null:
			result[k] = _val
	# maybe dangerous
	return result

func filter_dict(dict: Dictionary, callable: Callable) -> Dictionary:
	var result = {}
	var _dict = dict.duplicate(true)
	for k in _dict:
		var _cond = callable.call(k, _dict[k])
		if _cond == true:
			result[k] = _dict[k]
	return result


class BetterConfigFile:
	var cfg = ConfigFile.new()
	var filepath: String
	
	func _init(_filepath: String) -> void:
		if FileAccess.file_exists(_filepath):
			cfg.load(_filepath)
		else:
			FileAccess.open(_filepath, FileAccess.WRITE)
		
		filepath = _filepath
	
	func set_value(section: String, key: String, val) -> void:
		cfg.set_value(section, key, val)
	
	func get_value(section: String, key: String, default = null):
		return cfg.get_value(section, key, default)
	
	func save() -> int:
		return cfg.save(filepath)
	
	
	func set_base_value(key: String, val) -> void:
		return set_value("", key, val)
	
	func get_base_value(key: String, default = null):
		return get_value("", key, default)


# pssst, not stolen
static func s_to_hhmmss(total_seconds: float) -> String:
	#total_seconds = 12345
	var seconds:float = fmod(total_seconds , 60.0)
	var minutes:int   =  int(total_seconds / 60.0) % 60
	var hours:  int   =  int(total_seconds / 3600.0)
	var hhmmss_string:String = "%02dh %02dmin %02.1fs" % [hours, minutes, seconds]
	return hhmmss_string













