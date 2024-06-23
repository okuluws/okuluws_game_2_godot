# TODO: fix weird error when disconnecting from server and only if you moved??: _remove_node_cache: Condition "!pinfo" is true. Continuing.
# https://github.com/godotengine/godot/issues/92358

extends Window


# REQUIRED
var worlds

@export var players: Node
@export var items: Node
@export var overworld: Node
@export var client_ui_scene: PackedScene
@onready var main = worlds.main
var modules
var server_ip
var server_port
var server_node
var smapi = SceneMultiplayer.new()


func _on_tree_entered():
	modules = {
		"players": players,
		"items": items,
		"overworld": overworld,
	}
	smapi.peer_authenticating.connect(func(p):
		smapi.complete_auth(p)
		if server_node != null:
			server_node.smapi.complete_auth(smapi.get_unique_id())
			server_node.peers[smapi.get_unique_id()] = { "user_id": main.modules.pocketbase.user_id, "username": main.modules.pocketbase.username }
		else:
			smapi.send_auth(p, JSON.stringify({ "action": "create_ticket", "user_id": main.pb.user_id }).to_utf8_buffer())
	)
	smapi.set_auth_callback(func(p, raw_data):
		var data = JSON.parse_string(raw_data.get_string_from_utf8())
		if data.err != null:
			smapi.disconnect_peer(p)
		else:
			var ticket_id = data.ret
			var res = await main.pb.api_GET("collections/server_tickets/records/%s" % ticket_id, true)
			if res.response_code != 200:
				smapi.disconnect_peer(p)
			else:
				smapi.send_auth(p, JSON.stringify({ "action": "redeem_ticket", "ticket_id": ticket_id, "ticket_key": res.body.key }).to_utf8_buffer())
	)
	smapi.connected_to_server.connect(_on_connected_to_server)
	smapi.server_disconnected.connect(_on_server_disconnected)
	get_tree().set_multiplayer(smapi, get_path())


func _ready():
	print("starting client")
	var enet = ENetMultiplayerPeer.new()
	if server_node != null:
		enet.create_client("127.0.0.1", server_node.port)
	else:
		enet.create_client(server_ip, server_port)
	smapi.multiplayer_peer = enet


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
		queue_free()
