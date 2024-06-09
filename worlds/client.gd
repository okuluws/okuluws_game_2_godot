extends SubViewport


# REQUIRED
@export var main: Node
var server_ip
var server_port

@onready var home = main.home
@onready var pb = main.pb
@export var level: Node2D
@export var client_ui_scene: PackedScene
signal quit_world_queued
var ticket_token 
var ticket_id
var enet = ENetMultiplayerPeer.new()
var smapi = SceneMultiplayer.new()


func _enter_tree():
	get_tree().set_multiplayer(smapi, get_path())


func _exit_tree():
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())


func _ready():
	print("starting client")
	
	smapi.peer_authenticating.connect(func(p):
		if ticket_token == null or ticket_id == null:
			smapi.send_auth(p, JSON.stringify({ "user_id": pb.user_id }).to_utf8_buffer())
		else:
			smapi.send_auth(p, JSON.stringify({ "ticket_id": ticket_id, "ticket_token": ticket_token }).to_utf8_buffer())
			smapi.complete_auth(p)
	)
	smapi.set_auth_callback(func(p, data):
		ticket_id = data.get_string_from_utf8()
		var res = await pb.api_GET("collections/server_tickets/records/%s" % ticket_id, true)
		if res.response_code != 200:
			push_error("couldnt get ticket with id %s" % ticket_id);
			quit_world()
			return
		
		ticket_token = res.body.token
		smapi.send_auth(p, JSON.stringify({ "ticket_id": ticket_id, "ticket_token": ticket_token }).to_utf8_buffer())
		smapi.complete_auth(p)
	)
	
	enet.create_client(server_ip, server_port)
	smapi.multiplayer_peer = enet
	smapi.connected_to_server.connect(_on_connected_to_server)
	smapi.server_disconnected.connect(_on_server_disconnected)
	get_tree().set_multiplayer(smapi, get_path())


func _on_connected_to_server():
	print("connected to server %s with port %s" % [server_ip, server_port])
	add_child(client_ui_scene.instantiate())


func _on_server_disconnected():
	print("disconnected from server")


func quit_world():
	quit_world_queued.emit()
	enet.close.call_deferred()
	smapi.set_deferred("multiplayer_peer", null)
	home.add_child(home.title_screen_scene.instantiate())
	queue_free()
	print("quit server world")


