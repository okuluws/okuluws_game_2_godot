# TODO: fix weird error when disconnecting from server and only if you moved??: _remove_node_cache: Condition "!pinfo" is true. Continuing.
# https://github.com/godotengine/godot/issues/92358

extends Window


# REQUIRED
var worlds
var server_ip
var server_port

@export var players: Node
@export var items: Node
@export var client_ui_scene: PackedScene
@onready var main = worlds.main
var ticket_key 
var ticket_id
var enet = ENetMultiplayerPeer.new()
var smapi = SceneMultiplayer.new()


func _enter_tree():
	get_tree().set_multiplayer(smapi, get_path())


func _exit_tree():
	smapi.multiplayer_peer = null
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())
	main.home.show_main_menu()
	print("client shutdown")


func _ready():
	print("starting client")
	
	smapi.peer_authenticating.connect(func(p):
		if ticket_key == null or ticket_id == null:
			smapi.send_auth(p, JSON.stringify({ "user_id": main.pb.user_id }).to_utf8_buffer())
		else:
			smapi.send_auth(p, JSON.stringify({ "ticket_id": ticket_id, "ticket_key": ticket_key }).to_utf8_buffer())
			smapi.complete_auth(p)
	)
	smapi.set_auth_callback(func(p, data):
		ticket_id = data.get_string_from_utf8()
		var res = await main.pb.api_GET("collections/server_tickets/records/%s" % ticket_id, true)
		if res.response_code != 200:
			push_error("couldnt get ticket with id %s" % ticket_id);
			worlds.shutdown_client(self)
			return
		
		ticket_key = res.body.token
		smapi.send_auth(p, JSON.stringify({ "ticket_id": ticket_id, "ticket_key": ticket_key }).to_utf8_buffer())
		smapi.complete_auth(p)
	)
	
	enet.create_client(server_ip, server_port)
	smapi.multiplayer_peer = enet
	smapi.connected_to_server.connect(_on_connected_to_server)
	smapi.server_disconnected.connect(_on_server_disconnected)
	get_tree().set_multiplayer(smapi, get_path())


func _on_connected_to_server():
	print("connected to server %s with port %s" % [server_ip, server_port])
	var new_client_ui = client_ui_scene.instantiate()
	new_client_ui.client = self
	add_child(new_client_ui)


func _on_server_disconnected():
	worlds.close_client(self)
	print("disconnected from server")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		worlds.close_client(self)

