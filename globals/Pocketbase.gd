extends Node


var address = "127.0.0.1"
var port = 8090

var subscriptions = {}
var sse_client_id = ""

const CONFIG_FILEPATH = "user://pocketbase.cfg"
var authtoken: FuncU.ConfigFileSyncedValue
var username: FuncU.ConfigFileSyncedValue
var user_id: FuncU.ConfigFileSyncedValue

const PocketbaseType = preload("res://globals/Pocketbase.gd")


func _ready() -> void:
	authtoken = FuncU.ConfigFileSyncedValue.new(CONFIG_FILEPATH, "", "authtoken", "")
	username = FuncU.ConfigFileSyncedValue.new(CONFIG_FILEPATH, "", "username", "")
	user_id = FuncU.ConfigFileSyncedValue.new(CONFIG_FILEPATH, "", "user_id", "")
	_start_realtime()


class FetchResponse:
	var code: int
	var data
	func _init(code_, data_):
		code = code_
		data = data_

func create_record(collection: String, data: Dictionary, should_use_authtoken: bool = false) -> FetchResponse:
	var res = await fetch_api("collections/%s/records" % collection, HTTPClient.METHOD_POST, data, authtoken.value if should_use_authtoken else "")
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
		username.value = res.data.record.username
		user_id.value = res.data.record.id
		authtoken.value = res.data.token
	return FetchResponse.new(res.code, res.data.record if res.code == 200 else {})

func refresh_authtoken(collection: String, query_params: String = "") -> FetchResponse:
	var res = await fetch_api("collections/%s/auth-refresh%s" % [collection, query_params], HTTPClient.METHOD_POST, {}, authtoken.value)
	if res.code == 200:
		username.value = res.data.record.username
		user_id.value = res.data.record.id
		authtoken.value = res.data.token
	return FetchResponse.new(res.code, res.data.record if res.code == 200 else {})

func check_authtoken(collection: String, authtoken_: String, query_params: String = "") -> FetchResponse:
	var res = await fetch_api("collections/%s/auth-refresh%s" % [collection, query_params], HTTPClient.METHOD_POST, {}, authtoken_)
	return FetchResponse.new(res.code, res.data.record if res.code == 200 else {})

func patch_record(collection: String, record_id: String, data: Dictionary, should_use_authtoken: bool = false) -> FetchResponse:
	var res = await fetch_api("collections/%s/records/%s" % [collection, record_id], HTTPClient.METHOD_PATCH, data, authtoken.value if should_use_authtoken else "")
	return FetchResponse.new(res.code, res.data if res.code == 200 else {})

func subscribe(subscription_id: String, action: String, callback: Callable) -> FetchResponse:
	if not subscriptions.has(subscription_id):
		subscriptions[subscription_id] = []
	subscriptions[subscription_id].append({ "action": action, "callback": callback })
	return await fetch_api("realtime", HTTPClient.METHOD_POST, { "clientId": sse_client_id, "subscriptions": subscriptions.keys() })

# TODO: unsub only specifique callback, not all
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
	elif authtoken.value != "":
		headers.append("Authorization: %s" % authtoken.value)
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


func _get_sse_stream_data(stream: StreamPeer) -> Dictionary:
	var raw_string = (await _read_stream(stream)).replace("\r", "").get_slice("\n\n\n", 0)
	var subscription_id = FuncU.remove_enclosed_string(raw_string.get_slice("\nevent:", 1).get_slice("\ndata:", 0), "\n", "\n")
	var data_string = FuncU.remove_enclosed_string(raw_string.get_slice("\ndata:", 1), "\n", "\n")
	return { "subscription_id": subscription_id, "data": JSON.parse_string(data_string) }


func _start_realtime() -> void:
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
	
	sse_client_id = (await _get_sse_stream_data(tcp)).data.clientId
	while true:
		var event = await _get_sse_stream_data(tcp)
		FuncU.map_dict(subscriptions, func(subscription_id, subs):
			if subscription_id in [event.subscription_id, event.subscription_id.get_slice("/", 0)]:
				subs.map(func(sub):
					if sub.action in ["*", event.data.action]:
						sub.callback.call(event.data.record)
				)
		)
	
