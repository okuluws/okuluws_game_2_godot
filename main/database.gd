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


func authenticate(authcollection_name: String, identity: String, password: String) -> Dictionary:
	var body = JSON.stringify({
		"identity": identity,
		"password": password,
	})
	var headers = ["Content-Type: application/json"]
	http_node.request("%s/api/collections/%s/auth-with-password" % [url, authcollection_name], headers, HTTPClient.METHOD_POST, body)
	
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



