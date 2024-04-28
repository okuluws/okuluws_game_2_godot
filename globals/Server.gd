extends Node


var enet_peer = ENetMultiplayerPeer.new()

var host_record_id: String
var host_username: String
var host_password: String
var host_authtoken: String

@onready var account_n_profile_gui: ColorRect = $"/root/main/GUI/AccountNProfileManagment"
@onready var server_pannel: ColorRect = $"/root/main/GUI/ServerPannel"

@export var players: Dictionary

var server_config = ConfigFile.new()


func _ready():
	server_pannel.get_node("PrintProfiles").connect("pressed", _on_print_profiles_pressed)


func host_login(username: String, password: String) -> bool:
	var res = await Pocketbase.collection("hosts").auth(username, password)
	if res.code != 200:
		print_debug("couldnt authenticate as host <%s>" % username)
		return false
	
	host_record_id = res.data.record.id
	host_username = username
	host_password = password
	host_authtoken = res.data.token
	
	return true


func server_print(args):
	print("[SERVER|%d] " % multiplayer.get_unique_id(), args)

func start(port: int):
	server_config.load("user://server_config.cfg")
	if not await host_login(server_config.get_value("authentication", "username"), server_config.get_value("authentication", "password")):
		print_debug("failed to login host, aborting...")
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
func connect_player(peer_id: int, username: String, password: String, profile_id: String) -> void:
	var res = await Pocketbase.collection("users").auth(username, password, "?expand=player_profiles_via_user", false)
	if not res.code == 200:
		server_print("peer <%d> unsuccessfully attempted to login as <%s>" % [peer_id, username])
		return
	
	var user = res.data.record
	if not user.has("expand"):
		server_print("no profiles found on user <%s>" % username)
		return
	
	var all_profiles: Array = user.expand.player_profiles_via_user
	if not all_profiles.any(func(p): return p.id == profile_id):
		server_print("profile <%s> not found on user <%s>" % [profile_id, username])
		return
	
	
	var profile = all_profiles.filter(func(p): return p.id == profile_id)[0]
	players[user.id] = {
		"peer_id": peer_id,
		"user_username": user.username,
		"profile_record_id": profile.id,
		"should_lock_profile": false,
	}
	
	var player = EntitySpawner.spawn({
		"entity_name": "player",
		"properties": {
			"user_record_id": user.id,
			"name": user.id,
		},
	})
	
	Client.assign_player.rpc_id(peer_id, player.get_path())
	server_print("successfully connected peer <%s> as user <%s> on profile <%s>" % [peer_id, user.username, profile.name])


@rpc("any_peer")
func spawn_entity(data: Dictionary):
	# something has gone horribly wrong
	assert(is_multiplayer_authority())
	
	EntitySpawner.spawn(data)
	


func get_profile_data(profile_record_id: String):
	return (await Pocketbase.collection("player_profiles").record(profile_record_id)).data

func update_profile_entry(profile_record_id: String, entry: String, callable: Callable):
	assert(multiplayer.is_server())
	var user_record_id = players.find_key(players.values().filter(func(p): return p.profile_record_id == profile_record_id)[0])
	while players[user_record_id].should_lock_profile:
		await get_tree().process_frame
	
	players[user_record_id].should_lock_profile = true
	var profile = await get_profile_data(profile_record_id)
	await Pocketbase.collection("player_profiles").update(profile_record_id, { entry: callable.call(profile[entry]) })
	players[user_record_id].should_lock_profile = false


func _on_print_profiles_pressed():
	assert(multiplayer.is_server())
	print(players)


func try_item_fit_inventories(profile_record_id: String, item: Dictionary, inventory_names):
	assert(multiplayer.is_server())
	if inventory_names is String:
		inventory_names = [inventory_names]
	var res = { "is_success": false }
	await Server.update_profile_entry(profile_record_id, "inventories", func(inventories):
		for inventory_name in inventory_names:
			for k in Inventories.data[inventory_name]:
				if k in inventories[inventory_name] and inventories[inventory_name][k].item.type == item.type and Items.data[item.type].slot_size * (inventories[inventory_name][k].stack + 1) <= Inventories.data[inventory_name][k].capacity:
					inventories[inventory_name][k].stack += 1
					res.is_success = true
					return inventories
		
		for inventory_name in inventory_names:
			for k in Inventories.data[inventory_name]:
				if not k in inventories[inventory_name]:
					inventories[inventory_name][k] = {
						"item": item,
						"stack": 1
					}
					res.is_success = true
					return inventories
		
		return inventories
	)
	
	return res.is_success


@rpc("any_peer")
func move_inventory_item(profile_record_id, inventory_id, slot_id, inventory_dest_id, slot_dest_id, amount = null):
	await Server.update_profile_entry(profile_record_id, "inventories", func(inventories):
		Inventories.push_slot_A_to_B(inventories, inventory_id, slot_id, inventory_dest_id, slot_dest_id, amount)
		return inventories
	)


@rpc("any_peer")
func swap_inventory_item(profile_record_id, inventory, slot, inventory_dest, slot_dest):
	await Server.update_profile_entry(profile_record_id, "inventories", func(inventories):
		Inventories.swap_slot_A_with_B(inventories, inventory, slot, inventory_dest, slot_dest)
		return inventories
	)

