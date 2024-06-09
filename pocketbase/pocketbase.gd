extends Node


signal auth_changed
signal finished_ready
var auth_config_path = "user://pocketbase.cfg"
var auth_config = ConfigFile.new()
var auth_collection = "users"
var pb_url = "http://192.168.178.214:8090"

var authtoken:
	set(val): auth_config.set_value("", "token", val)
	get: return auth_config.get_value("", "token")

var username:
	set(val): auth_config.set_value("", "username", val)
	get: return auth_config.get_value("", "username")

var user_id:
	set(val): auth_config.set_value("", "user_id", val)
	get: return auth_config.get_value("", "user_id")


func _ready():
	if auth_config.load(auth_config_path) == OK and has_auth():
		refresh_auth()
		auth_changed.emit()
	else:
		print("no valid auth config found")
	
	finished_ready.emit()


func _fetch(url: String, headers: Array, http_method: int, data: Dictionary, timeout: float = 2):
	var http_requester = HTTPRequest.new()
	http_requester.timeout = timeout
	add_child(http_requester)
	http_requester.request(url, headers, http_method, JSON.stringify(data))
	var res = await http_requester.request_completed
	remove_child(http_requester)
	return { "result": res[0], "response_code": res[1], "headers": Array(res[2]), "body": JSON.parse_string(res[3].get_string_from_utf8()) if not res[3].is_empty() else {} }


func _set_auth_from_res(res):
	authtoken = res.body.token
	username = res.body.record.username
	user_id = res.body.record.id
	auth_changed.emit()


func api_POST(rel_url: String, data: Dictionary, auth_request: bool = false):
	var headers = ["Content-Type: application/json"]
	if auth_request: headers.append("Authorization: %s" % authtoken)
	return await _fetch("%s/api/%s" % [pb_url, rel_url], headers, HTTPClient.METHOD_POST, data)


func api_PATCH(rel_url: String, data: Dictionary, auth_request: bool = false):
	var headers = ["Content-Type: application/json"]
	if auth_request: headers.append("Authorization: %s" % authtoken)
	return await _fetch("%s/api/%s" % [pb_url, rel_url], headers, HTTPClient.METHOD_PATCH, data)


func api_GET(rel_url: String, auth_request: bool = false):
	return await _fetch("%s/api/%s" % [pb_url, rel_url], ["Authorization: %s" % authtoken] if auth_request else [], HTTPClient.METHOD_GET, {})


func create_record(collection_name: String, data: Dictionary = {}):
	return await api_POST("collections/%s" % collection_name, data)


func delete_record(collection_name: String, record_id: String, auth_request: bool = false):
	return await _fetch("%s/api/%s/%s" % [pb_url, collection_name, record_id], ["Authorization: %s" % authtoken] if auth_request else [], HTTPClient.METHOD_DELETE, {})


func refresh_auth():
	var res = await api_POST("collections/%s/auth-refresh" % auth_collection, {}, true)
	if res.response_code != 200:
		push_warning("couldn't refresh auth")
		return
	_set_auth_from_res(res)


func auth_with_password(identity: String, password: String):
	var res = await api_POST("collections/%s/auth-with-password" % auth_collection, { "identity": identity, "password": password })
	if res.response_code != 200:
		push_warning("failed auth")
		return FAILED
	
	_set_auth_from_res(res)
	return OK


func create_auth_record(_username: String, password: String):
	var res = await api_POST("collections/%s/records" % auth_collection, { "username": _username, "password": password, "passwordConfirm": password })
	if not (res.result == HTTPRequest.RESULT_SUCCESS and res.response_code == 200):
		push_warning("couldnt create user")
		return FAILED
	
	return OK


func delete_auth():
	auth_config.clear()
	auth_config.save(auth_config_path)
	auth_changed.emit()


func has_auth():
	return auth_config.has_section_key("", "username") and auth_config.has_section_key("", "user_id") and auth_config.has_section_key("", "token")

