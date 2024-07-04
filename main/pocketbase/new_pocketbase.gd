extends Node


signal current_auth_changed

var address: String
var port: int

var auth_save_path: String = "user://pocketbase_auth.cfg"
var auth_collection_id
# NOTE: maybe inefficient, but no care, no need
var current_auth_record_id:
	get: return _auth_cfg.get_value("", "current_auth_record_id")
	set(val): _auth_cfg.set_value("", "current_auth_record_id", val)

var _auth_cfg = ConfigFile.new()


func init(p_address: String, p_port: int, p_auth_collection_id: String = "users") -> void:
	address = p_address
	port = p_port
	auth_collection_id = p_auth_collection_id


func start() -> void:
	print(_get_auth_cfg_section("", ""))
	if not FileAccess.file_exists(auth_save_path): _auth_cfg_save()
	_auth_cfg_load()
	auth_refresh()
	var t_start = Time.get_ticks_msec()
	api_health_check(func(res):
		if res.err != null or res.code != 200: push_error("pocketbase server failed me ;(")
		else: print("response time: %dms" % Time.get_ticks_msec() - t_start)
	)
	_start_realtime()
	


func api_health_check(callback: Callable = Callable()) -> void:
	_request(_get_base_url() + "/api/health", func(err, code, _body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null }),
		)


func create_record(collection_id: String, data: Dictionary, callback: Callable = Callable(), use_auth_header: bool = false) -> void:
	_request(_get_collection_url(collection_id) + "/records", func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(body.get_string_from_utf8()) }),
		JSON.stringify(data), HTTPClient.METHOD_POST, ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func delete_record(collection_id: String, record_id: String, callback: Callable = Callable(), use_auth_header: bool = false) -> void:
	_request(_get_record_url(collection_id, record_id), func(err, code, _body, _headers):
			if err != null or code != 204:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null }),
		"", HTTPClient.METHOD_DELETE, ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func update_record(collection_id: String, record_id: String, data: Dictionary, callback: Callable = Callable(), use_auth_header: bool = false) -> void:
	_request(_get_record_url(collection_id, record_id), func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(body.get_string_from_utf8()) }),
		JSON.stringify(data), HTTPClient.METHOD_PATCH, ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func get_single_record(collection_id: String, record_id: String, callback: Callable, use_auth_header: bool = false) -> void:
	_request(_get_record_url(collection_id, record_id), func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(body.get_string_from_utf8()) }),
		"", HTTPClient.METHOD_GET, ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func auth_with_password(identity: String, password: String, callback: Callable = Callable()) -> void:
	_request(_get_collection_url(auth_collection_id) + "/auth-with-password", func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(body.get_string_from_utf8()) }),
		{ "identity": identity, "password": password }, HTTPClient.METHOD_POST)


func auth_register(username: String, password: String, callback: Callable = Callable()) -> void:
	create_record(auth_collection_id, { "username": username, "password": password, "passwordConfirm": password }, callback)


func auth_refresh(callback: Callable = Callable()) -> void:
	_request(_get_collection_url(auth_collection_id) + "/auth-refresh", func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(body.get_string_from_utf8()) }),
	{}, HTTPClient.METHOD_POST, ["Authorization: %s" % _get_current_authtoken()])


func set_auth_record(record_id: String) -> void:
	current_auth_record_id = record_id
	current_auth_changed.emit()


func has_current_auth() -> bool:
	return current_auth_record_id != null


func subscribe(path: String, on_event: Callable, event_action: String = "*") -> void: pass
func unsubscribe(on_event: Callable) -> void: pass


func _get_base_url():
	return "http://%s:%d" % [address, port]


func _get_collection_url(collection_id):
	return _get_base_url() + "/api/collections/%s" % collection_id


func _get_record_url(collection_id, record_id):
	return _get_collection_url(collection_id) + "/records/%s" % record_id


func _get_current_authtoken():
	return _auth_cfg.get_value(_get_auth_cfg_section(auth_collection_id, current_auth_record_id), "authtoken")


func _get_auth_cfg_section(collection_id, record_id):
	return Array(_auth_cfg.get_sections()).map(func(section): return JSON.parse_string(section)).filter(func(properties): properties.collection_id == collection_id and properties.record_id == record_id)[0]


func _auth_cfg_save():
	if _auth_cfg.save(auth_save_path) != OK: push_error("couldn't save auth config")


func _auth_cfg_load():
	if _auth_cfg.load(auth_save_path) != OK: push_error("couldn't load auth config")


func _request(url, on_request_completed = null, request_data = "", method = HTTPClient.METHOD_GET, custom_headers = []):
	var temp_http_node = HTTPRequest.new()
	temp_http_node.request_completed.connect(func(result, response_code, headers, body):
		if result != HTTPRequest.RESULT_SUCCESS:
			if on_request_completed != null: on_request_completed.call({ "err": "request failed you" })
			temp_http_node.queue_free()
			return
		if on_request_completed != null: on_request_completed.call({ "err": null, "code": response_code, "body": body, "headers": headers })
		temp_http_node.queue_free()
	, Object.CONNECT_ONE_SHOT)
	
	add_child(temp_http_node)
	if temp_http_node.request(url, PackedStringArray(custom_headers), method, request_data) != OK:
		if on_request_completed != null: on_request_completed.call({ "err": "couldn't create request" })
		temp_http_node.queue_free()
		return


func _start_realtime(): pass


func _ready():
	start()



