extends Node


var address: String
var port: int


func init(p_address: String, p_port: int) -> void:
	address = p_address
	port = p_port


func start() -> void:
	api_health_check(func(res):
		if res.has_err or res.code != 200: push_error("couldn't connect to pocketbase server")
	)
	_start_realtime()
	


func api_health_check(on_request_completed: Callable) -> void:
	_request(_get_base_url() + "/api/health", on_request_completed)


func create_record(collection_id: String, on_request_completed: Callable, data: Dictionary, auth_config = null):
	_request(_get_collection_url(collection_id), on_request_completed, data, HTTPClient.METHOD_POST, [_get_authtoken_header(auth_config.collection_id, auth_config.record_id)] if auth_config != null else [])


func delete_record(collection_id: String, record_id: String, on_request_completed: Callable, auth_config = null):
	_request(_get_record_url(collection_id, record_id), on_request_completed, "", HTTPClient.METHOD_DELETE, [_get_authtoken_header(auth_config.collection_id, auth_config.record_id)] if auth_config != null else [])


func update_record(collection_id: String, record_id: String, on_request_completed: Callable, auth_config = null): pass
func get_record(collection_id: String, record_id: String, on_request_completed: Callable, auth_config = null): pass

func auth_login(collection_id: String, identity: String, password: String): pass
func auth_register(collection_id: String, username: String, password: String): pass
func auth_refresh(): pass
func auth_save(): pass
func auth_load(): pass
func auth_set_user(record_id: String): pass
func auth_get_user(): pass
func auth_set_collection(collection_id: String): pass
func auth_get_collection(): pass
func auth_is_valid(): pass

func subscribe(path: String, on_event: Callable, event_action: String = "*") -> void: pass
func unsubscribe(on_event: Callable) -> void: pass


func _get_base_url():
	return "http://%s:%d" % [address, port]


func _get_collection_url(collection_id: String):
	return _get_base_url() + "/api/collections/%s" % collection_id


func _get_record_url(collection_id: String, record_id: String):
	return _get_collection_url(collection_id) + "/records/%s" % record_id


func _get_authtoken_header(collection_id: String, record_id: String):
	var authtoken = null # TODO: get authtoken
	return "Authorization: %s" % authtoken


func _request(url, on_request_completed, request_data = "", method = HTTPClient.METHOD_GET, custom_headers = []):
	var temp_http_node = HTTPRequest.new()
	temp_http_node.request_completed.connect(func(result, response_code, headers, body):
		if result != HTTPRequest.RESULT_SUCCESS:
			on_request_completed.call({ "has_err": true })
			temp_http_node.queue_free()
			return
		on_request_completed.call({ "has_err": false, "code": response_code, "body": body, "headers": headers })
		temp_http_node.queue_free()
	, Object.CONNECT_ONE_SHOT)
	
	add_child(temp_http_node)
	if temp_http_node.request(url, PackedStringArray(custom_headers), method, request_data) != OK:
		on_request_completed.call({ "has_err": true })
		temp_http_node.queue_free()
		return


func _start_realtime(): pass


func _ready():
	start()



