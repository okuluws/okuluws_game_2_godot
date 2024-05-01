extends Node


var enet_peer = ENetMultiplayerPeer.new()
@export var players: Dictionary

@onready var account_n_profile_gui: ColorRect = $"/root/main/GUI/AccountNProfileManagment"
@onready var server_pannel: ColorRect = $"/root/main/GUI/ServerPannel"


func _ready():
	server_pannel.get_node("PrintProfiles").connect("pressed", _on_print_profiles_pressed)


func server_print(args):
	print("[SERVER|%d] " % multiplayer.get_unique_id(), args)

func start(identity: String, password: String, port: int):
	Pocketbase.authtoken = FuncU.ConfigFileSyncedValue.new("user://server_pocketbase.cfg", "", "authtoken", "")
	Pocketbase.username = FuncU.ConfigFileSyncedValue.new("user://server_pocketbase.cfg", "", "username", "")
	Pocketbase.user_id = FuncU.ConfigFileSyncedValue.new("user://server_pocketbase.cfg", "", "user_id", "")
	
	var res = await Pocketbase.auth_w_password("hosts", identity, password)
	if res.code != 200:
		print_debug("couldnt authenticate as host <%s>" % identity)
	
	server_print("successfully authenticated as %s" % Pocketbase.username.value)
	
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
func connect_player(peer_id: int, authtoken: String, profile_id: String) -> void:
	var res = await Pocketbase.check_authtoken("users", authtoken, "?expand=player_profiles_via_user")
	if not res.code == 200:
		server_print("unsuccessfull login attempt from peer <%d>" % peer_id)
		return
	
	var user = res.data
	if not user.has("expand"):
		server_print("no profiles found on user <%s>" % user.username)
		return
	
	var all_profiles: Array = user.expand.player_profiles_via_user
	if not all_profiles.any(func(p): return p.id == profile_id):
		server_print("profile <%s> not found on user <%s>" % [profile_id, user.username])
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
	return (await Pocketbase.get_record("player_profiles", profile_record_id)).data

func update_profile_entry(profile_record_id: String, entry: String, callable: Callable):
	assert(multiplayer.is_server())
	var user_record_id = players.find_key(players.values().filter(func(p): return p.profile_record_id == profile_record_id)[0])
	while players[user_record_id].should_lock_profile:
		await get_tree().process_frame
	
	players[user_record_id].should_lock_profile = true
	var profile = await get_profile_data(profile_record_id)
	await Pocketbase.patch_record("player_profiles", profile_record_id, { entry: callable.call(profile[entry]) }, true)
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
		for inventory_uid in inventory_names:
			var inventory = inventories[inventory_uid]
			for k in range(Inventories.config[inventory.type_id].slot_count).map(func(val): return str(val)):
				if k in inventory.slots and inventory.slots[k].item.type_id == item.type_id and Items.config[item.type_id].slot_size * (inventory.slots[k].stack + 1) <= Inventories.config[inventory.type_id].slot_capacity:
					inventory.slots[k].stack += 1
					res.is_success = true
					return inventories
		
		for inventory_uid in inventory_names:
			var inventory = inventories[inventory_uid]
			for k in range(Inventories.config[inventory.type_id].slot_count).map(func(val): return str(val)):
				if not k in inventory.slots:
					inventories[inventory_uid].slots[k] = {
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

