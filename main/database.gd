extends Node


@export var url: String
@export var http_node: HTTPRequest


func parse_res_body(res):
	return JSON.parse_string(res[3].get_string_from_utf8())


func get_record(collection_name: String, record_id: String) -> Dictionary:
	http_node.request("%s/api/collections/%s/records/%s" % [url, collection_name, record_id])
	var res = await http_node.request_completed
	if res[1] == 200:
		return parse_res_body(res)
	else:
		print_debug(parse_res_body(res))
		return {}


func get_records(collection_name: String, query_params: String = "") -> Array:
	http_node.request("%s/api/collections/%s/records%s" % [url, collection_name, query_params])
	var res = await http_node.request_completed
	if res[1] == 200:
		return parse_res_body(res)["items"]
	else:
		print_debug(parse_res_body(res))
		return []


func authenticate(authcollection_name: String, identity: String, password: String, query_params: String = "") -> Dictionary:
	var body = JSON.stringify({
		"identity": identity,
		"password": password,
	})
	var headers = ["Content-Type: application/json"]
	http_node.request("%s/api/collections/%s/auth-with-password%s" % [url, authcollection_name, query_params], headers, HTTPClient.METHOD_POST, body)
	
	var res = await http_node.request_completed
	if res[1] == 200:
		return parse_res_body(res)
	else:
		print_debug(parse_res_body(res))
		return {}


func create_record(collection_name: String, data: Dictionary, authtoken: String = "") -> Dictionary:
	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	if authtoken:
		headers.append("Authorization: %s" % authtoken)
	
	http_node.request(url + "/api/collections/%s/records" % collection_name, headers, HTTPClient.METHOD_POST, body)
	var res = await http_node.request_completed
	if res[1] == 200:
		return parse_res_body(res)
	else:
		print_debug(parse_res_body(res))
		return {}
	


func update_record(collection_name: String, record_id: String, data: Dictionary, authtoken: String = "") -> Dictionary:
	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	if authtoken:
		headers.append("Authorization: %s" % authtoken)
	
	http_node.request(url + "/api/collections/%s/records/%s" % [collection_name, record_id], headers, HTTPClient.METHOD_PATCH, body)
	var res = await http_node.request_completed
	if res[1] == 200:
		return parse_res_body(res)
	else:
		print_debug(parse_res_body(res))
		return {}



# TRYING TO DO SSE, DEFINETLY NOT COPIED CODE
# EDIT: IT WORKS OMFG HOW?
func _setup_tcp_stream() -> StreamPeerTCP:
	var tcp = StreamPeerTCP.new()
	
	var err_conn_tcp = tcp.connect_to_host("127.0.0.1", 8090)
	assert(err_conn_tcp == OK)
	tcp.poll()
	var tcp_status = tcp.get_status()
	while tcp_status != StreamPeerTCP.STATUS_CONNECTED:
		await get_tree().process_frame
		tcp.poll()
		tcp_status = tcp.get_status()
	
	return tcp
	

func _start_sse_stream(stream: StreamPeer) -> void:
	var _url = "/api/realtime"
	var request_line = "GET %s HTTP/1.1" % _url
	var headers = [
		"Host: %s" % "127.0.0.1",
		"Accept: text/event-stream",
	]
	var request = ""
	request += request_line + "\n" # request line
	request += "\n".join(headers) + "\n" # headers
	request += "\n" # empty line 
	stream.put_data(request.to_ascii_buffer())

func _read_stream_response(stream: StreamPeer) -> String:
	stream.poll()
	var available_bytes = stream.get_available_bytes()
	while available_bytes == 0:
		await get_tree().process_frame
		stream.poll()
		available_bytes = stream.get_available_bytes()
	
	return stream.get_string(available_bytes)

class EventData:
	var type: String
	var data: Dictionary

func _parse_event_data(event_str: String) -> EventData:
	var event_lines = event_str.split("\n")
	if event_lines.size() != 4:
		return null
	
	const EVENT_TYPE_PREFIX = "event:"
	const EVENT_DATA_PREFIX = "data:"
	
	var event_type_line = event_lines[2]
	if !event_type_line.begins_with(EVENT_TYPE_PREFIX):
		return null
	var event_data_line = event_lines[3]
	if !event_data_line.begins_with(EVENT_DATA_PREFIX):
		return null
	
	var event_type_str = event_type_line.substr(EVENT_TYPE_PREFIX.length())
	var event_data_str = event_data_line.substr(EVENT_DATA_PREFIX.length())
	var event_data_json = JSON.parse_string(event_data_str)
	if event_data_json == null:
		event_data_json = {}
	var event = EventData.new()
	event.type = event_type_str
	event.data = event_data_json
	return event

func _parse_response_event_data(response: String) -> Array[Dictionary]:
	var response_parts = response.replace("\r", "").split("\n\n")
	var event_data: Array[Dictionary] = []
	for response_part in response_parts:
		var event = _parse_event_data(response_part)
		if event == null:
			continue
		
		event_data.append(event.data)
	
	return event_data



func _ready():
	var tcp = await _setup_tcp_stream()
	#var stream = await _setup_tls_stream(tcp)
	
	_start_sse_stream(tcp)
	var initial_response = await _read_stream_response(tcp)
	var client_id = _parse_response_event_data(initial_response)[0]["clientId"]
	
	
	http_node.request("%s/api/realtime" % url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({
		"clientId": client_id,
		"subscriptions": ["player_profiles"],
	}))
	var res = await http_node.request_completed
	
	while true:
		var response = await _read_stream_response(tcp)
		var events = _parse_response_event_data(response)
		for event in events:
			print(event)

