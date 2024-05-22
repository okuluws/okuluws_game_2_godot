extends Node


const auth_file = "user://pocketbase.cfg"
const auth_collection = "users"
const pb_url = "http://192.168.178.214:8090"

var authtoken = null
var username = null
var user_id = null

signal auth_changed
signal finished_ready


func _ready():
	if FileAccess.file_exists(auth_file):
		_load_auth()
		refresh_auth()
	
	finished_ready.emit()



func _fetch(url: String, headers: Array, http_method: int, data: Dictionary, timeout: float = 2):
	var http_requester = HTTPRequest.new()
	http_requester.timeout = timeout
	add_child(http_requester)
	http_requester.request(url, headers, http_method, JSON.stringify(data))
	var res = await http_requester.request_completed
	remove_child(http_requester)
	return { "result": res[0], "response_code": res[1], "headers": Array(res[2]), "body": JSON.parse_string(res[3].get_string_from_utf8()) if not res[3].is_empty() else {} }


func _load_auth():
	var f = ConfigFile.new()
	if f.load(auth_file) != OK: return FAILED
	if f.get_value("", "username", "") == "" or f.get_value("", "token", "") == "" or f.get_value("", "user_id", "") == "": return FAILED
	username = f.get_value("", "username")
	authtoken = f.get_value("", "token")
	user_id = f.get_value("", "user_id")
	auth_changed.emit()
	return OK


func _save_auth():
	var f = ConfigFile.new()
	f.set_value("", "username", username)
	f.set_value("", "token", authtoken)
	f.set_value("", "user_id", user_id)
	return f.save(auth_file)

func _set_auth_w_res(res):
	authtoken = res.body.token
	username = res.body.record.username
	user_id = res.body.record.id
	auth_changed.emit()
	return _save_auth()


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
	if not (res.result == HTTPRequest.RESULT_SUCCESS and res.response_code == 200):
		return FAILED
	
	_set_auth_w_res(res)
	return OK

func auth_with_password(identity: String, password: String):
	var res = await api_POST("collections/%s/auth-with-password" % auth_collection, { "identity": identity, "password": password })
	if not (res.result == HTTPRequest.RESULT_SUCCESS and res.response_code == 200):
		print_debug("failed auth")
		return FAILED
	
	_set_auth_w_res(res)
	return OK

func create_auth_record(_username: String, password: String):
	var res = await api_POST("collections/%s/records" % auth_collection, { "username": _username, "password": password, "passwordConfirm": password })
	if not (res.result == HTTPRequest.RESULT_SUCCESS and res.response_code == 200):
		print_debug("failed auth")
		print(res)
		return FAILED
	
	return OK


func delete_auth():
	authtoken = ""
	username = ""
	user_id = ""
	_save_auth()
	auth_changed.emit()




