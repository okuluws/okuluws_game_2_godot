extends Node


func _ready() -> void:
	_start_realtime()


const Self = preload("res://globals/Pocketbase.gd")
var address = "127.0.0.1"
var port = 8090
var authtoken: String

var subscriptions = {}
var sse_client_id = ""


class FetchResponse:
	var code: int
	var data
	func _init(code_, data_):
		code = code_
		data = data_


class Collection:
	var pocketbase: Self
	var collection_name: String
	func _init(pocketbase_, collection_name_) -> void:
		pocketbase = pocketbase_
		collection_name = collection_name_
	
	func create(data: Dictionary) -> FetchResponse:
		var res = await pocketbase.fetch_api("collections/%s/records" % collection_name, HTTPClient.METHOD_POST, data, ["Content-Type: application/json", "Authorization: %s" % pocketbase.authtoken if pocketbase.authtoken else ""])
		return FetchResponse.new(res.code, res.data if res.code == 200 else {})
	
	func record(record_id: String) -> FetchResponse:
		var res = await pocketbase.fetch_api("collections/%s/records/%s" % [collection_name, record_id])
		return FetchResponse.new(res.code, res.data if res.code == 200 else {})
	
	func records(query_params: String = "") -> FetchResponse:
		var res = await pocketbase.fetch_api("collections/%s/records%s" % [collection_name, query_params]) 
		return FetchResponse.new(res.code, res.data.items if res.code == 200 else {})
	
	func auth(username: String, password: String, query_params: String = "", should_save_token: bool = true) -> FetchResponse:
		var res = await pocketbase.fetch_api("collections/%s/auth-with-password%s" % [collection_name, query_params], HTTPClient.METHOD_POST, { "identity": username, "password": password })
		if res.code == 200 and should_save_token:
			pocketbase.authtoken = res.data.token
		
		return FetchResponse.new(res.code, res.data if res.code == 200 else {})
	
	func update(record_id: String, data: Dictionary) -> FetchResponse:
		var res = await pocketbase.fetch_api("collections/%s/records/%s" % [collection_name, record_id], HTTPClient.METHOD_PATCH, data, ["Content-Type: application/json", "Authorization: %s" % pocketbase.authtoken if pocketbase.authtoken else ""])
		return FetchResponse.new(res.code, res.data if res.code == 200 else {})
	
	func subscribe(record_id: String, action: String, callback: Callable) -> FetchResponse:
		var sub_id = "%s%s" % [collection_name, ("/%s" % record_id) if record_id != "" else ""]
		if not pocketbase.subscriptions.has(sub_id):
			pocketbase.subscriptions[sub_id] = []
		pocketbase.subscriptions[sub_id].append({ "action": action, "callback": callback })
		
		return await pocketbase.fetch_api("realtime", HTTPClient.METHOD_POST, { "clientId": pocketbase.sse_client_id, "subscriptions": pocketbase.subscriptions.keys() }, ["Content-Type: application/json"])
	
	func unsubscribe(record_id: String) -> FetchResponse:
		var sub_id = "%s%s" % [collection_name, ("/%s" % record_id) if record_id != "" else ""]
		pocketbase.subscriptions.erase(sub_id)
		return await pocketbase.fetch_api("realtime", HTTPClient.METHOD_POST, { "clientId":  pocketbase.sse_client_id, "subscriptions":  pocketbase.subscriptions.keys() }, ["Content-Type: application/json"])


func fetch_api(url: String, http_method: int = HTTPClient.METHOD_GET, data: Dictionary = {}, headers: Array[String] = ["Content-Type: application/json"]) -> FetchResponse:
	var http_requester = HTTPRequest.new()
	http_requester.timeout = 2
	add_child(http_requester)
	http_requester.request("http://%s:%d/api/%s" % [address, port, url], headers, http_method, JSON.stringify(data))
	var res = await http_requester.request_completed
	remove_child(http_requester)
	return FetchResponse.new(res[1], JSON.parse_string(res[3].get_string_from_utf8()) if res[3] else {})


func collection(collection_name) -> Collection:
	return Collection.new(self, collection_name)





# SSE

func _read_stream(stream: StreamPeer) -> String:
	stream.poll()
	var available_bytes = stream.get_available_bytes()
	while available_bytes == 0:
		await get_tree().process_frame
		stream.poll()
		available_bytes = stream.get_available_bytes()
	
	return stream.get_string(available_bytes)


func _get_sse_stream_data(stream: StreamPeer):
	var raw_string = await _read_stream(stream)
	var raw_data_string_array = Array(raw_string.substr(raw_string.find("\ndata:") + 1).trim_prefix("data:").replace("\r", "").split("\n"))
	
	var actual_data_string = ""
	var n = 0
	while n < raw_data_string_array.size():
		actual_data_string += raw_data_string_array[n]
		n += 2
	return JSON.parse_string(actual_data_string)


func _start_realtime():
	var tcp = StreamPeerTCP.new()
	var err_conn_tcp = tcp.connect_to_host(address, port)
	assert(err_conn_tcp == OK)
	tcp.poll()
	var tcp_status = tcp.get_status()
	while tcp_status != StreamPeerTCP.STATUS_CONNECTED:
		await get_tree().process_frame
		tcp.poll()
		tcp_status = tcp.get_status()
	
	tcp.put_data(("""\
GET /api/realtime HTTP/1.1
Host: %s
Accept: text/event-stream

""" % address)
	.to_ascii_buffer())
	
	sse_client_id = (await _get_sse_stream_data(tcp)).clientId
	while true:
		var event = await _get_sse_stream_data(tcp)
		for k in subscriptions:
			if not k.begins_with(event.record.collectionName): continue
			
			if k.contains("/"):
				if k.get_slice("/", 1) != event.record.id: continue
			
			for s in subscriptions[k]:
				if s.action != event.action and s.action != "*": continue
				s.callback.call(event.record)
