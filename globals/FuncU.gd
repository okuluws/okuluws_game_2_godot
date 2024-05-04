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
