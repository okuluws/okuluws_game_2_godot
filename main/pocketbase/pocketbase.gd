extends Node


signal current_auth_updated

var address = "127.0.0.1"
var port = 20071

var auth_save_path: String = "user://pocketbase_auth.cfg"
# NOTE: maybe inefficient, but no care, no need
var current_auth_collection_id:
	get: return _auth_cfg.get_value("", "current_auth_collection_id")
	set(val): _auth_cfg.set_value("", "current_auth_collection_id", val)
var current_auth_record_id:
	get: return _auth_cfg.get_value("", "current_auth_record_id")
	set(val): _auth_cfg.set_value("", "current_auth_record_id", val)

var _auth_cfg = ConfigFile.new()


func start() -> void:
	if FileAccess.file_exists(auth_save_path):
		_auth_cfg_load()
	else:
		_auth_cfg_save()
	
	
	var t_start = Time.get_ticks_msec()
	api_health_check(func(res):
		if res.err != null: push_error("pocketbase server doesnt want me ;(")
		else: print("api response time: %dms" % Time.get_ticks_msec() - t_start)
	)
	
	if has_current_auth():
		refresh_current_auth(func(res): if res.err != null or res.code != 200: push_error("couldn't refresh auth"))
	
	_start_realtime()


func api_health_check(callback: Callable) -> void:
	_request(_get_base_url() + "/api/health", func(res):
			if res.err != null or res.code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null }),
		)


func create_record(collection_id: String, data: Dictionary, callback: Callable, use_auth_header: bool = false) -> void:
	_request(_get_collection_url(collection_id) + "/records", func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(body.get_string_from_utf8()) }),
		JSON.stringify(data), HTTPClient.METHOD_POST, ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func delete_record(collection_id: String, record_id: String, callback: Callable, use_auth_header: bool = false) -> void:
	_request(_get_record_url(collection_id, record_id), func(err, code, _body, _headers):
			if err != null or code != 204:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null }),
		"", HTTPClient.METHOD_DELETE, ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func update_record(collection_id: String, record_id: String, data: Dictionary, callback: Callable, use_auth_header: bool = false) -> void:
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


func auth_with_password(auth_collection_id: String, identity: String, password: String, callback: Callable) -> void:
	_request(_get_collection_url(auth_collection_id) + "/auth-with-password", func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				var parsed_body = JSON.parse_string(body.get_string_from_utf8())
				_auth_cfg.set_value(var_to_str({ "collection_id": parsed_body.record.collectionId, "record_id": parsed_body.record.id }), "authtoken", parsed_body.token)
				current_auth_collection_id = parsed_body.record.collectionId
				current_auth_record_id = parsed_body.record.id
				current_auth_updated.emit()
				callback.call({ "err": null, "res": parsed_body }),
		{ "identity": identity, "password": password }, HTTPClient.METHOD_POST)


func auth_register(auth_collection_id: String, username: String, password: String, callback: Callable) -> void:
	create_record(auth_collection_id, { "username": username, "password": password, "passwordConfirm": password }, callback)


func refresh_current_auth(callback: Callable) -> void:
	_request(_get_collection_url(current_auth_collection_id) + "/auth-refresh", func(err, code, body, _headers):
			if err != null or code != 200:
				callback.call({ "err": "idk" })
			else:
				var parsed_body = JSON.parse_string(body.get_string_from_utf8())
				_auth_cfg.set_value(var_to_str({ "collection_id": parsed_body.record.collectionId, "record_id": parsed_body.record.id }), "authtoken", parsed_body.token)
				current_auth_updated.emit()
				callback.call({ "err": null, "res": parsed_body }),
	{}, HTTPClient.METHOD_POST, ["Authorization: %s" % _get_current_authtoken()])


func has_current_auth() -> bool:
	return _auth_cfg.has_section_key("", "current_auth_collection_id") and _auth_cfg.has_section_key("", "current_auth_record_id")


#func subscribe(path: String, on_event: Callable, event_action: String = "*") -> void: pass
#func unsubscribe(on_event: Callable) -> void: pass


func _get_base_url():
	return "http://%s:%d" % [address, port]


func _get_collection_url(collection_id):
	return _get_base_url() + "/api/collections/%s" % collection_id


func _get_record_url(collection_id, record_id):
	return _get_collection_url(collection_id) + "/records/%s" % record_id


func _get_current_authtoken():
	return _auth_cfg.get_value(_get_auth_cfg_section(current_auth_collection_id, current_auth_record_id), "authtoken")


func _get_auth_cfg_section(collection_id, record_id):
	for section in _auth_cfg.get_sections():
		var parsed_section = str_to_var(section)
		if parsed_section.collection_id == collection_id and parsed_section.record_id == record_id:
			return section


func _auth_cfg_save():
	if _auth_cfg.save(auth_save_path) != OK: push_error("couldn't save auth config")


func _auth_cfg_load():
	if _auth_cfg.load(auth_save_path) != OK: push_error("couldn't load auth config")


func _request(url, on_request_completed: Callable, request_data = "", method = HTTPClient.METHOD_GET, custom_headers = []):
	var temp_http_node = HTTPRequest.new()
	temp_http_node.timeout = 4
	temp_http_node.request_completed.connect(func(result, response_code, headers, body):
		if result != HTTPRequest.RESULT_SUCCESS:
			on_request_completed.call({ "err": "request failed you" })
			temp_http_node.queue_free()
			return
		on_request_completed.call({ "err": null, "code": response_code, "body": body, "headers": headers })
		temp_http_node.queue_free()
	, Object.CONNECT_ONE_SHOT)
	
	add_child(temp_http_node)
	if temp_http_node.request(url, PackedStringArray(custom_headers), method, request_data) != OK:
		on_request_completed.call({ "err": "couldn't create request" })
		temp_http_node.queue_free()
		return


func _start_realtime(): pass


func _ready():
	start()

