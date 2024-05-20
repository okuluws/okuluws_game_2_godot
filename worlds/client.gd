extends SubViewport


signal quit_world_queued

var server_ip = null
var server_port = null
var ticket_token = null
var ticket_id = null

var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()


func _ready():
	_PRINT_STAMP("starting client connecting to %s on port %d ..." % [server_ip, server_port])
	
	smapi.peer_authenticating.connect(func(p):
		if ticket_token == null or ticket_id == null:
			smapi.send_auth(p, JSON.stringify({ "user_id": $"/root/Main/Pocketbase".user_id }).to_ascii_buffer())
		else:
			smapi.send_auth(p, JSON.stringify({ "ticket_id": ticket_id, "ticket_token": ticket_token }).to_utf8_buffer())
			smapi.complete_auth(p)
	)
	smapi.set_auth_callback(func(p, data: PackedByteArray):
		ticket_id = data.get_string_from_utf8()
		var res = await $"/root/Main/Pocketbase".api_GET("collections/server_tickets/records/%s" % ticket_id, true)
		if res.response_code != 200: push_error("couldnt find ticket with id %s??" % ticket_id); return
		ticket_token = res.body.token
		
		smapi.send_auth(p, JSON.stringify({ "ticket_id": ticket_id, "ticket_token": ticket_token }).to_utf8_buffer())
		smapi.complete_auth(p)
	)
	
	enet.create_client(server_ip, server_port)
	smapi.multiplayer_peer = enet
	smapi.connected_to_server.connect(_on_connected_to_server)
	smapi.server_disconnected.connect(_on_server_disconnected)
	get_tree().set_multiplayer(smapi, get_path())
	
	_PRINT_STAMP("starting client done.")
	

func _on_connected_to_server():
	_PRINT_STAMP("connected to server peer")
	add_child(load("res://worlds/client_inworld_options.tscn").instantiate())


func _on_server_disconnected():
	_PRINT_STAMP("disconnected from server peer")
	

func _PRINT_STAMP(s: String):
	print("[%s][%s] %s" % [name, Time.get_time_string_from_system(), s])


func quit_world():
	quit_world_queued.emit()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	enet.close()
	queue_free()
	$"/root/Main/Home".add_child(load($"/root/Main/Home".title_screen_file).instantiate())
	_PRINT_STAMP("quit world")
	

