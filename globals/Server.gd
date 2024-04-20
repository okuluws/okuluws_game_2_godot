extends Node


var enet_peer = ENetMultiplayerPeer.new()

var host_record_id: String
var host_username: String
var host_password: String
var host_authtoken: String

@onready var account_n_profile_gui: ColorRect = $"/root/main/GUI/AccountNProfileManagment"
@onready var server_pannel: ColorRect = $"/root/main/GUI/ServerPannel"

@export var players: Dictionary


func _ready():
	server_pannel.get_node("PrintProfiles").connect("pressed", _on_print_profiles_pressed)


func host_login(username: String, password: String) -> bool:
	var host = await Database.authenticate("hosts", username, password)
	
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
	
	EntitySpawner.spawn({
		"entity_name": "overworld",
	})
	
	Camera.zoom = Vector2(0.4, 0.4)
	


func _on_client_connected(peer_id):
	server_print("connected peer: %d" % peer_id)


func _on_client_disconnected(peer_id):
	server_print("disconnected peer: %d" % peer_id)



@rpc("any_peer")
func connect_player(peer_id: int, username: String, password: String, profile_id: String):
	var user = await Database.authenticate("users", username, password, "?expand=player_profiles_via_user")
	#print(user)
	if not user:
		print_debug("djahjha, you thought")
		return
	
	if not user["record"].has("expand"):
		print_debug("player doesnt have any profiles?")
		return
	
	var profile = user["record"]["expand"]["player_profiles_via_user"].filter(func(p): return p.id == profile_id)[0]
	if not profile:
		print_debug("player profile not found")
		return
	
	players[user["record"]["id"]] = {
		"peer_id": peer_id,
		"user_username": user["record"]["username"],
		"profile_record_id": profile["id"],
		"should_lock_profile": false,
	}
	
	var player = EntitySpawner.spawn({
		"entity_name": "player",
		"properties": {
			"user_record_id": user["record"]["id"],
			"name": user["record"]["id"],
		},
	})
	
	server_print("connected user %s, profile: %s" % [user["record"]["username"], profile["name"]])
	Client.assign_player.rpc_id(peer_id, player.get_path())


@rpc("any_peer")
func spawn_entity(data: Dictionary):
	# something has gone horribly wrong
	assert(is_multiplayer_authority())
	
	EntitySpawner.spawn(data)
	


func get_profile_data(profile_record_id: String):
	assert(multiplayer.is_server())
	return (await Database.get_record("player_profiles", profile_record_id))["json"]

func patch_profile_data(profile_record_id: String, profile_data: Dictionary):
	await Database.update_record("player_profiles", profile_record_id, { "json": profile_data }, host_authtoken)

func update_profile_entry(profile_record_id: String, entry: String, callable: Callable):
	assert(multiplayer.is_server())
	var user_record_id = players.find_key(players.values().filter(func(p): return p.profile_record_id == profile_record_id)[0])
	while players[user_record_id].should_lock_profile:
		await get_tree().process_frame
	
	players[user_record_id].should_lock_profile = true
	var profile_data = await get_profile_data(profile_record_id)
	profile_data[entry] = callable.call(profile_data[entry])
	await patch_profile_data(profile_record_id, profile_data)
	players[user_record_id].should_lock_profile = false



func _on_print_profiles_pressed():
	assert(multiplayer.is_server())
	print(players)


func try_item_fit_inventory(profile_record_id: String, item: Dictionary, inventory_name: String):
	var res = { "is_success": false }
	await Server.update_profile_entry(profile_record_id, "inventories", func(inventories):
		for k in Inventories.data[inventory_name]:
			if not k in inventories[inventory_name]:
				inventories[inventory_name][k] = {
					"item": item,
					"stack": 1
				}
				res.is_success = true
				return inventories
			
			if inventories[inventory_name][k].item.name == item.name and Items.data[item.name].slot_size * (inventories[inventory_name][k].stack + 1) <= Inventories.data[inventory_name][k].capacity:
				inventories[inventory_name][k].stack += 1
				res.is_success = true
				return inventories
		
		return inventories
	)
	
	return res.is_success
