extends Node


func _init():
	config = FuncU.BetterConfig.new("user://pocketbase.cfg")
	config.subscribe("idk", "username", func(val):
		username = val
	)
	config.subscribe("idk", "authtoken", func(val):
		authtoken = val
	)
	config.subscribe("idk", "user_id", func(val):
		user_id = val
	)

func _ready() -> void:
	_start_realtime()


var address = "127.0.0.1"
var port = 8090
var authtoken: String
var username: String
var user_id: String

var subscriptions = {}
var sse_client_id = ""

var config: FuncU.BetterConfig


class FetchResponse:
	var code: int
	var data
	func _init(code_, data_):
		code = code_
		data = data_


func create_record(collection: String, data: Dictionary) -> FetchResponse:
	var res = await fetch_api("collections/%s/records" % collection, HTTPClient.METHOD_POST, data)
	return FetchResponse.new(res.code, res.data if res.code == 200 else {})

func get_record(collection: String, record_id: String) -> FetchResponse:
	var res = await fetch_api("collections/%s/records/%s" % [collection, record_id])
	return FetchResponse.new(res.code, res.data if res.code == 200 else {})

func get_records(collection: String, query_params: String = "") -> FetchResponse:
	var res = await fetch_api("collections/%s/records%s" % [collection, query_params]) 
	return FetchResponse.new(res.code, res.data.items if res.code == 200 else {})

func auth_w_password(collection: String, identity: String, password: String, query_params: String = "") -> FetchResponse:
	var res = await fetch_api("collections/%s/auth-with-password%s" % [collection, query_params], HTTPClient.METHOD_POST, { "identity": identity, "password": password })
	if res.code == 200:
		config.set_value("idk", "username", res.data.record.username)
		config.set_value("idk", "user_id", res.data.record.id)
		config.set_value("idk", "authtoken", res.data.token)
	return FetchResponse.new(res.code, res.data.record if res.code == 200 else {})

func refresh_authtoken(collection: String, query_params: String = "") -> FetchResponse:
	var res = await fetch_api("collections/%s/auth-refresh%s" % [collection, query_params], HTTPClient.METHOD_POST, {}, authtoken)
	if res.code == 200:
		config.set_value("idk", "username", res.data.record.username)
		config.set_value("idk", "user_id", res.data.record.id)
		config.set_value("idk", "authtoken", res.data.token)
	return FetchResponse.new(res.code, res.data.record if res.code == 200 else {})

func check_authtoken(collection: String, authtoken_: String, query_params: String = "") -> FetchResponse:
	var res = await fetch_api("collections/%s/auth-refresh%s" % [collection, query_params], HTTPClient.METHOD_POST, {}, authtoken_)
	return FetchResponse.new(res.code, res.data.record if res.code == 200 else {})

func patch_record(collection: String, record_id: String, data: Dictionary, should_use_authtoken: bool = false) -> FetchResponse:
	var res = await fetch_api("collections/%s/records/%s" % [collection, record_id], HTTPClient.METHOD_PATCH, data, authtoken if should_use_authtoken else "")
	return FetchResponse.new(res.code, res.data if res.code == 200 else {})

func subscribe(subscription_id: String, action: String, callback: Callable) -> FetchResponse:
	if not subscriptions.has(subscription_id):
		subscriptions[subscription_id] = []
	subscriptions[subscription_id].append({ "action": action, "callback": callback })
	return await fetch_api("realtime", HTTPClient.METHOD_POST, { "clientId": sse_client_id, "subscriptions": subscriptions.keys() })

func unsubscribe(subscription_id: String) -> FetchResponse:
	subscriptions.erase(subscription_id)
	return await fetch_api("realtime", HTTPClient.METHOD_POST, { "clientId":  sse_client_id, "subscriptions": subscriptions.keys() })



func fetch(url: String, http_method: int, data: Dictionary, headers: Array[String]) -> FetchResponse:
	var http_requester = HTTPRequest.new()
	http_requester.timeout = 2
	add_child(http_requester)
	http_requester.request(url, headers, http_method, JSON.stringify(data))
	var res = await http_requester.request_completed
	remove_child(http_requester)
	return FetchResponse.new(res[1], JSON.parse_string(res[3].get_string_from_utf8()) if res[3] else {})


func fetch_api(url: String, http_method: int = HTTPClient.METHOD_GET, data: Dictionary = {}, authtoken_: String = "") -> FetchResponse:
	var headers = ["Content-Type: application/json"] as Array[String]
	if authtoken_ != "":
		headers.append("Authorization: %s" % authtoken_)
	elif authtoken != "":
		headers.append("Authorization: %s" % authtoken)
	return await fetch("http://%s:%d/api/%s" % [address, port, url], http_method, data, headers)






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
