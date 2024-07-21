extends Node


const GameMain = preload("res://main.gd")
const OptionalString = GameMain.FuncU.OptionalString
const OptionalDictionary = GameMain.FuncU.OptionalDictionary
const address = "192.168.178.214"
const port = 20071
const _auth_config_file = "user://auth.cfg"
signal current_auth_updated
var func_u: GameMain.FuncU
# NOTE: maybe inefficient, but no care, no need
var current_auth_collection_id:
	get: return _auth_config.get_value("", "current_auth_collection_id")
	set(val): _auth_config.set_value("", "current_auth_collection_id", val)
var current_auth_record_id:
	get: return _auth_config.get_value("", "current_auth_record_id")
	set(val): _auth_config.set_value("", "current_auth_record_id", val)
var _auth_config = ConfigFile.new()


func init(p_game_main: GameMain) -> void:
	func_u = p_game_main.func_u
	if not FileAccess.file_exists(_auth_config_file):
		_save_auth_config()
	_load_auth_config()


func create_record(collection_id: String, data: Dictionary, should_authorize: bool) -> Signal:
	return request_api("/collections/%s/records" % collection_id, HTTPClient.METHOD_POST, data, OptionalString.new(get_authtoken()) if should_authorize else null, 200)


func delete_record(collection_id: String, record_id: String, should_authorize: bool) -> Signal:
	return request_api("/collections/%s/records/%s" % [collection_id, record_id], HTTPClient.METHOD_DELETE, {}, OptionalString.new(get_authtoken()) if should_authorize else null, 204)


func update_record(collection_id: String, record_id: String, data: Dictionary, should_authorize: bool) -> Signal:
	return request_api("/collections/%s/records/%s" % [collection_id, record_id], HTTPClient.METHOD_PATCH, data, OptionalString.new(get_authtoken()) if should_authorize else null, 200)


func view_record(collection_id: String, record_id: String, should_authorize: bool) -> Signal:
	return request_api("/collections/%s/records/%s" % [collection_id, record_id], HTTPClient.METHOD_GET, {}, OptionalString.new(get_authtoken()) if should_authorize else null, 200)


func auth_with_password(auth_collection_id: String, identity: String, password: String) -> Signal:
	var sgnl = request_api("/collections/%s/auth-refresh" % auth_collection_id, HTTPClient.METHOD_POST, { "identity": identity, "password": password }, null, 200)
	sgnl.connect(func(err: OptionalString, result: OptionalDictionary):
		if err == null:
			var section = var_to_str({ "collection_id": result.val.record.collectionId, "record_id": result.val.record.id })
			_auth_config.set_value(section, "authtoken", result.val.token)
			_auth_config.set_value(section, "username", result.val.record.username)
			current_auth_collection_id = result.val.record.collectionId
			current_auth_record_id = result.val.record.id
			_save_auth_config()
			current_auth_updated.emit()
	)
	return sgnl


func refresh_auth() -> Signal:
	var sgnl = request_api("/collections/%s/auth-refresh" % current_auth_collection_id, HTTPClient.METHOD_POST, {}, OptionalString.new(get_authtoken()), 200)
	sgnl.connect(func(err: OptionalString, result: OptionalDictionary):
		if err == null:
			var section = var_to_str({ "collection_id": result.val.record.collectionId, "record_id": result.val.record.id })
			_auth_config.set_value(section, "authtoken", result.val.token)
			_auth_config.set_value(section, "username", result.val.record.username)
			current_auth_collection_id = result.val.record.collectionId
			current_auth_record_id = result.val.record.id
			_save_auth_config()
			current_auth_updated.emit()
	)
	return sgnl


func is_authed() -> bool:
	return _auth_config.has_section_key("", "current_auth_collection_id") and _auth_config.has_section_key("", "current_auth_record_id")


func unset_auth() -> void:
	current_auth_collection_id = null
	current_auth_record_id = null
	_save_auth_config()
	current_auth_updated.emit()


func get_username() -> String:
	return _get_auth_config_value(current_auth_collection_id, current_auth_record_id, "username")


func get_authtoken() -> String:
	return _get_auth_config_value(current_auth_collection_id, current_auth_record_id, "authtoken")


func _get_auth_config_value(collection_id: String, record_id: String, key: String) -> Variant:
	for section in _auth_config.get_sections():
		if section == "": continue
		var parsed_section = str_to_var(section)
		if parsed_section.collection_id == collection_id and parsed_section.record_id == record_id:
			_auth_config.get_value(section, key)
	func_u.panic("coudln't find auth config for %s %s" % [collection_id, record_id])
	return null


func _save_auth_config() -> void:
	func_u.save_config_file(_auth_config, _auth_config_file)


func _load_auth_config() -> void:
	func_u.load_config_file(_auth_config, _auth_config_file)


## return type: signal(err: OptionalString, result: OptionalDictionary)
func request_api(url: String, method: HTTPClient.Method, data: Dictionary, authtoken: OptionalString, expected_response_code: int) -> Signal:
	var node = HTTPRequest.new()
	node.timeout = 16
	node.add_user_signal("pocketbase_signal", [{ "name": "result", "type": TYPE_OBJECT }])
	node.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == expected_response_code:
			node.pocketbase_signal.emit(null, OptionalDictionary.new(JSON.parse_string(body.get_string_from_utf8())))
		else:
			node.pocketbase_signal.emit(OptionalString.new("request failed %s" % url), null)
	)
	var headers = ["content-type:application/json"]
	if authtoken != null:
		headers.append(["Authorization: %s" % authtoken.val])
	add_child(node)
	if node.request("http://%s:%d/api%s" % [address, port, url], PackedStringArray(headers), method, JSON.stringify(data)) != OK:
		node.pocketbase_signal.emit(OptionalString.new("couldn't create request %s" % url), null)
	return node.pocketbase_signal
