extends Node


signal current_auth_updated

var address = "192.168.178.214"
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
	var callback_lock = false
	if FileAccess.file_exists(auth_save_path):
		_auth_cfg_load()
	else:
		_auth_cfg_save()
	
	var t_start = Time.get_ticks_msec()
	callback_lock = true
	api_health_check(func(res):
		if res.err != null: push_error("pocketbase server doesnt want me ;(")
		else: print("pocketbase api response time: %dms" % (Time.get_ticks_msec() - t_start))
		callback_lock = false
	)
	while callback_lock: await get_tree().process_frame
	
	if has_current_auth():
		callback_lock = true
		refresh_current_auth(func(res):
			if res.err != null or res.code != 200: push_error("couldn't refresh auth")
			callback_lock = false
		)
		while callback_lock: await get_tree().process_frame
	
	_start_realtime()


func api_health_check(callback: Callable) -> void:
	_request(_get_base_url() + "/api/health", func(res):
			if res.err != null or res.code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null }),
		"", HTTPClient.METHOD_GET, ["content-type:application/json"])


func create_record(collection_id: String, data: Dictionary, callback: Callable, use_auth_header: bool = false) -> void:
	_request(_get_collection_url(collection_id) + "/records", func(res):
			if res.err != null or res.code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(res.body.get_string_from_utf8()) }),
		JSON.stringify(data), HTTPClient.METHOD_POST, ["content-type:application/json"] + ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func delete_record(collection_id: String, record_id: String, callback: Callable, use_auth_header: bool = false) -> void:
	_request(_get_record_url(collection_id, record_id), func(res):
			if res.err != null or res.code != 204:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null }),
		"", HTTPClient.METHOD_DELETE, ["content-type:application/json"] + ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func update_record(collection_id: String, record_id: String, data: Dictionary, callback: Callable, use_auth_header: bool = false) -> void:
	_request(_get_record_url(collection_id, record_id), func(res):
			if res.err != null or res.code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(res.body.get_string_from_utf8()) }),
		JSON.stringify(data), HTTPClient.METHOD_PATCH, ["content-type:application/json"] + ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func get_single_record(collection_id: String, record_id: String, callback: Callable, use_auth_header: bool = false) -> void:
	_request(_get_record_url(collection_id, record_id), func(res):
			if res.err != null or res.code != 200:
				callback.call({ "err": "idk" })
			else:
				callback.call({ "err": null, "record": JSON.parse_string(res.body.get_string_from_utf8()) }),
		"", HTTPClient.METHOD_GET, ["content-type:application/json"] + ["Authorization: %s" % _get_current_authtoken()] if use_auth_header else [])


func auth_with_password(auth_collection_id: String, identity: String, password: String, callback: Callable) -> void:
	_request(_get_collection_url(auth_collection_id) + "/auth-with-password", func(res):
			if res.err != null or res.code != 200:
				callback.call({ "err": "idk" })
			else:
				var parsed_body = JSON.parse_string(res.body.get_string_from_utf8())
				var section = var_to_str({ "collection_id": parsed_body.record.collectionId, "record_id": parsed_body.record.id })
				_auth_cfg.set_value(section, "authtoken", parsed_body.token)
				_auth_cfg.set_value(section, "username", parsed_body.record.username)
				current_auth_collection_id = parsed_body.record.collectionId
				current_auth_record_id = parsed_body.record.id
				_auth_cfg_save()
				current_auth_updated.emit()
				callback.call({ "err": null, "record": parsed_body.record }),
		JSON.stringify({ "identity": identity, "password": password }), HTTPClient.METHOD_POST, ["content-type:application/json"])


func refresh_current_auth(callback: Callable) -> void:
	_request(_get_collection_url(current_auth_collection_id) + "/auth-refresh", func(res):
			if res.err != null or res.code != 200:
				callback.call({ "err": "idk" })
			else:
				var parsed_body = JSON.parse_string(res.body.get_string_from_utf8())
				var section = var_to_str({ "collection_id": parsed_body.record.collectionId, "record_id": parsed_body.record.id })
				_auth_cfg.set_value(section, "authtoken", parsed_body.token)
				_auth_cfg.set_value(section, "username", parsed_body.record.username)
				_auth_cfg_save()
				current_auth_updated.emit()
				callback.call({ "err": null, "record": parsed_body.record }),
	{}, HTTPClient.METHOD_POST, ["content-type:application/json", "Authorization: %s" % _get_current_authtoken()])


func has_current_auth() -> bool:
	return _auth_cfg.has_section_key("", "current_auth_collection_id") and _auth_cfg.has_section_key("", "current_auth_record_id")


func unset_current_auth() -> void:
	current_auth_collection_id = null
	current_auth_record_id = null
	_auth_cfg_save()
	current_auth_updated.emit()


func get_current_username():
	return _auth_cfg.get_value(_get_auth_cfg_section(current_auth_collection_id, current_auth_record_id), "username")


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
		if section.is_empty(): continue
		var parsed_section = str_to_var(section)
		if parsed_section.collection_id == collection_id and parsed_section.record_id == record_id:
			return section


func _auth_cfg_save():
	if _auth_cfg.save(auth_save_path) != OK: push_error("couldn't save auth config")


func _auth_cfg_load():
	if _auth_cfg.load(auth_save_path) != OK: push_error("couldn't load auth config")


func _request(url, on_request_completed, request_data, method, custom_headers):
	var temp_http_node = HTTPRequest.new()
	temp_http_node.timeout = 4
	temp_http_node.request_completed.connect(func(result, response_code, headers, body):
		if result != HTTPRequest.RESULT_SUCCESS:
			on_request_completed.call({ "err": "couldn't request %s" % url })
			temp_http_node.queue_free()
			return
		on_request_completed.call({ "err": null, "code": response_code, "body": body, "headers": headers })
		temp_http_node.queue_free()
	, Object.CONNECT_ONE_SHOT)
	
	add_child(temp_http_node)
	if temp_http_node.request(url, PackedStringArray(custom_headers), method, request_data) != OK:
		on_request_completed.call({ "err": "couldn't create request" })
		temp_http_node.queue_free()


func _start_realtime(): pass


func _ready():
	start()

