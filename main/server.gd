extends Node2D


@export var main_node: Node2D
var enet_peer = ENetMultiplayerPeer.new()

@export var database: Node
var host_record_id: String
var host_username: String
var host_password: String
var host_authtoken: String

@export var account_n_profile_gui: ColorRect
@export var server_pannel: ColorRect

@export var players: Dictionary


func host_login(username: String, password: String) -> bool:
	var host = await database.authenticate("hosts", username, password)
	
	if not host:
		print_debug("invalid user")
		return false
	
	host_record_id = host["record"]["id"]
	host_username = host["record"]["username"]
	host_password = password
	host_authtoken = host["token"]
	
	return true


func server_print(args):
	print("[SERVER|%d] " % multiplayer.get_unique_id(), args)

func start(port: int, username: String, password: String):
	if not await host_login(username, password):
		print_debug("couldnt login as %s" % username)
		return
	
	server_print("successfully authenticated as %s" % host_username)
	
	
	multiplayer.peer_connected.connect(_on_client_connected)
	multiplayer.peer_disconnected.connect(_on_client_disconnected)
	
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	server_print("serving on port %d" % port)
	
	
	server_print("loading world")
	
	account_n_profile_gui.visible = false
	server_pannel.visible = true
	
	main_node.entity_spawner.spawn({
		"entity": "overworld",
		"set_main_node": true,
	})
	
	
	main_node.camera.zoom = Vector2(0.4, 0.4)
	


func _on_client_connected(peer_id):
	server_print("connected peer: %d" % peer_id)


func _on_client_disconnected(peer_id):
	server_print("disconnected peer: %d" % peer_id)
	main_node.world.get_node("%s" % peer_id).queue_free()
	players.erase(peer_id)


@rpc("any_peer")
func connect_player(peer_id: int, username: String, password: String, profile_id: String):
	var user = await database.authenticate("users", username, password)
	if not user:
		print_debug("djahjha, you thought")
		return
	
	var profile = await database.get_record("player_profiles", profile_id)
	
	server_print("connected user %s, profile: %s" % [user["record"]["username"], profile["name"]])
	
	players[peer_id] = {
		"user_record_id": user["record"]["id"],
		"profile_record_id": profile["id"],
	}
	
	main_node.entity_spawner.spawn({
		"entity": "player",
		"set_main_node": true,
		"properties": {
			"peer_id": peer_id,
			"name": str(peer_id),
			"display_name": user["record"]["username"],
		}
	})
	
	main_node.client.assign_player.rpc_id(peer_id, str(peer_id))


@rpc("any_peer")
func spawn_entity(data: Dictionary):
	# something has gone horribly wrong
	assert(is_multiplayer_authority())
	
	main_node.entity_spawner.spawn(data)
	


func get_profile_data(profile_record_id: String):
	assert(multiplayer.is_server())
	return (await database.get_record("player_profiles", profile_record_id))["json"]


func update_profile_entry(peer_id: int, entry: String, callable: Callable):
	assert(multiplayer.is_server())
	var profile_data = await get_profile_data(players[peer_id]["profile_record_id"])
	profile_data[entry] = callable.call(profile_data[entry])
	await database.update_record("player_profiles", players[peer_id]["profile_record_id"], { "json": profile_data }, host_authtoken)


func _on_save_pressed():
	assert(multiplayer.is_server())
	print(players)







