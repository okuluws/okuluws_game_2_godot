extends Node


@export var url: String


var subscriptions = {}
var sse_client_id = null


func _ready():
	await _start_realtime()


# helper
func _fetch(fetch_url, http_method = HTTPClient.METHOD_GET, data = {}, headers = ["Content-Type: application/json"], should_log_on_non_200_code = true):
	#print("fetching %s" % fetch_url)
	var http_requester = HTTPRequest.new()
	add_child(http_requester)
	http_requester.request(fetch_url, headers, http_method, JSON.stringify(data))
	var res = await http_requester.request_completed
	if not res[1] == 200 and should_log_on_non_200_code:
		print_debug("fetch >>%s<< has response code >>%s<<" % [fetch_url, res[1]])
	
	remove_child(http_requester)
	return {
		"code": res[1],
		"data": JSON.parse_string(res[3].get_string_from_utf8()) if res[3] else null
	}
	



func get_record(collection_name: String, record_id: String, query_params: String = ""):
	return (await _fetch("%s/api/collections/%s/records/%s%s" % [url, collection_name, record_id, query_params])).data


func get_records(collection_name: String, query_params: String = "") -> Array:
	return (await _fetch("%s/api/collections/%s/records%s" % [url, collection_name, query_params])).data.items


func authenticate(authcollection_name: String, identity: String, password: String, query_params: String = ""):
	return (await _fetch("%s/api/collections/%s/auth-with-password%s" % [url, authcollection_name, query_params], HTTPClient.METHOD_POST, { "identity": identity, "password": password })).data


func create_record(collection_name: String, data: Dictionary, authtoken: String = "", query_params: String = "") -> Dictionary:
	return (await _fetch("%s/api/collections/%s/records%s" % [url, collection_name, query_params], HTTPClient.METHOD_POST, data, ["Content-Type: application/json", "Authorization: %s" % authtoken if authtoken else ""])).data


func update_record(collection_name: String, record_id: String, data: Dictionary, authtoken: String = "", query_params: String = "") -> Dictionary:
	return (await _fetch("%s/api/collections/%s/records/%s%s" % [url, collection_name, record_id, query_params], HTTPClient.METHOD_PATCH, data, ["Content-Type: application/json", "Authorization: %s" % authtoken if authtoken else ""])).data


func subscribe(collection_name: String, action: String, callback: Callable):
	if not subscriptions.has(collection_name):
		subscriptions[collection_name] = []
	subscriptions[collection_name].append({ "action": action, "callback": callback })
	
	await _fetch("%s/api/realtime" % url, HTTPClient.METHOD_POST, { "clientId": sse_client_id, "subscriptions": subscriptions.keys() }, ["Content-Type: application/json"], false)

func unsubscribe(collection_name):
	subscriptions.erase(collection_name)
	await _fetch("%s/api/realtime" % url, HTTPClient.METHOD_POST, { "clientId": sse_client_id, "subscriptions": subscriptions.keys() }, ["Content-Type: application/json"], false)


# TRYING TO DO SSE, DEFINETLY NOT COPIED CODE
# EDIT: IT WORKS OMFG HOW?
func _setup_sse_tcp() -> StreamPeerTCP:
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


func _read_stream(stream: StreamPeer) -> String:
	stream.poll()
	var available_bytes = stream.get_available_bytes()
	while available_bytes == 0:
		await get_tree().process_frame
		stream.poll()
		available_bytes = stream.get_available_bytes()
	
	return stream.get_string(available_bytes)


# ;)
func _get_sse_stream_data(stream: StreamPeer):
	return JSON.parse_string(Array((await _read_stream(stream)).replace("\r", "").split("\n")).filter(func(s): return s.begins_with("data:"))[0].trim_prefix("data:"))


func _start_realtime():
	var tcp = await _setup_sse_tcp()
	_start_sse_stream(tcp)
	#var stream = await _setup_tls_stream(tcp)
	
	sse_client_id = (await _get_sse_stream_data(tcp))["clientId"]
	#await subscribe("player_profiles", "*", func(r): print(r))
	#await _fetch("%s/api/realtime" % url, HTTPClient.METHOD_POST, { "clientId": sse_client_id, "subscriptions": ["player_profiles"] }, ["Content-Type: application/json"], false)
	while true:
		var event = await _get_sse_stream_data(tcp)
		for k in subscriptions:
			if not k.begins_with(event["record"]["collectionName"]): continue
			
			if k.contains("/"):
				if k.get_slice("/", 1) != event["record"]["id"]: continue
			
			for s in subscriptions[k]:
				if s["action"] != event["action"] and s["action"] != "*": continue
				s["callback"].call(event["record"])
