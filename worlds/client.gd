extends SubViewport


signal quit_world_queued
const IS_SERVER = false
@onready var home = $"/root/Main/Home"
@onready var pocketbase = $"/root/Main/Pocketbase"
var client_ui_scene = load("res://worlds/client_ui.tscn")
var server_ip
var server_port
var ticket_token 
var ticket_id

var enet := ENetMultiplayerPeer.new()
var smapi := SceneMultiplayer.new()


func _enter_tree():
	get_tree().set_multiplayer(smapi, get_path())


func _exit_tree():
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())


func _ready():
	_PRINT_STAMP("starting client connecting to %s on port %d ..." % [server_ip, server_port])
	
	smapi.peer_authenticating.connect(func(p):
		if ticket_token == null or ticket_id == null:
			smapi.send_auth(p, JSON.stringify({ "user_id": pocketbase.user_id }).to_ascii_buffer())
		else:
			smapi.send_auth(p, JSON.stringify({ "ticket_id": ticket_id, "ticket_token": ticket_token }).to_utf8_buffer())
			smapi.complete_auth(p)
	)
	smapi.set_auth_callback(func(p, data: PackedByteArray):
		ticket_id = data.get_string_from_utf8()
		var res = await pocketbase.api_GET("collections/server_tickets/records/%s" % ticket_id, true)
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
	add_child(client_ui_scene.instantiate())


func _on_server_disconnected():
	_PRINT_STAMP("disconnected from server peer")
	

func _PRINT_STAMP(s: String):
	print("[%s][%s] %s" % [name, Time.get_time_string_from_system(), s])


func quit_world():
	quit_world_queued.emit()
	enet.close.call_deferred()
	smapi.set_deferred("multiplayer_peer", null)
	queue_free()
	home.add_child(load("res://home/title_screen.tscn").instantiate())
	_PRINT_STAMP("quit world")
	

