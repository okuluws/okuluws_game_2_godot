extends Node


var enet_peer = ENetMultiplayerPeer.new()
var player_gui: CanvasLayer
var player: CharacterBody2D


@onready var account_n_profile_gui: ColorRect = $"/root/main/GUI/AccountNProfileManagment"
@onready var inventory_gui: GridContainer = $"/root/main/GUI/Inventory"
@onready var hotbar_gui: GridContainer = $"/root/main/GUI/Hotbar"
@onready var limbo_gui: Control = $"/root/main/GUI/Limbo"


var user_record_id: String
var user_username: String
var user_password: String
var user_authtoken: String
var profile_record_id: String
var profile_name: String

var config = ConfigFile.new()



func _ready():
	var err = config.load("user://config.cfg")
	if err != OK:
		config.save("user://config.cfg")
	
	
	if config.get_value("client", "username", false) and config.get_value("client", "password", false):
		if await user_login(config.get_value("client", "username"), config.get_value("client", "password")):
			account_n_profile_gui.label_user.text = "[center]Logged in as %s" % user_username
	
	if config.get_value("client", "profile", false):
		if await set_profile(config.get_value("client", "profile")):
			account_n_profile_gui.label_profile.text = "[center]Current Profile: %s" % profile_name
	
	if user_record_id:
		account_n_profile_gui.itemlist_profiles.clear()
		account_n_profile_gui.itemlist_profiles_data.clear()
		for p in await Database.get_records("player_profiles", "?filter=(user.id='%s')" % user_record_id):
			account_n_profile_gui.itemlist_profiles.add_item(p["name"])
			account_n_profile_gui.itemlist_profiles_data.append(p["id"])
	
	
	account_n_profile_gui.get_node("Login").connect("pressed", _on_login_pressed)
	account_n_profile_gui.get_node("CreateProfile").connect("pressed", _on_create_profile_pressed)
	account_n_profile_gui.get_node("ProfileList").connect("item_selected", _on_profile_list_item_selected)
	account_n_profile_gui.get_node("Join").connect("pressed", _on_join_pressed)




func user_login(username: String, password: String) -> bool:
	var user = await Database.authenticate("users", username, password)
	
	if not user:
		print_debug("invalid user")
		return false
	
	user_record_id = user["record"]["id"]
	user_username = user["record"]["username"]
	user_password = password
	user_authtoken = user["token"]
	
	config.set_value("client", "username", username)
	config.set_value("client", "password", password)
	config.save("user://config.cfg")
	
	return true


func _on_login_pressed():
	await user_login(account_n_profile_gui.input_username.text, account_n_profile_gui.input_password.text)
	account_n_profile_gui.label_user.text = "[center]Logged in as %s" % user_username
	
	
	account_n_profile_gui.itemlist_profiles.clear()
	account_n_profile_gui.itemlist_profiles_data.clear()
	for p in await Database.get_records("player_profiles", "?filter=(user.id='%s')" % user_record_id):
		account_n_profile_gui.itemlist_profiles.add_item(p["name"])
		account_n_profile_gui.itemlist_profiles_data.append(p["id"])
	

func set_profile(id: String) -> bool:
	var profile = await Database.get_record("player_profiles", id)
	if not profile:
		print_debug("profile doesnt exist")
		return false
	
	profile_record_id = profile["id"]
	profile_name = profile["name"]
	
	config.set_value("client", "profile", id)
	config.save("user://config.cfg")
	
	return true


func _on_create_profile_pressed():
	var new_profile_name = account_n_profile_gui.input_new_profile_name.text
	
	var new_profile = await Database.create_record("player_profiles", {
		"user": user_record_id,
		"name": new_profile_name,
		"player_type": ["square", "widesquare", "triangle"].pick_random()
	}, user_authtoken)
	
	if not new_profile:
		print_debug("failed to create new profile")
		return
	
	
	account_n_profile_gui.itemlist_profiles.clear()
	account_n_profile_gui.itemlist_profiles_data.clear()
	for p in await Database.get_records("player_profiles", "?filter=(user.id='%s')" % user_record_id):
		account_n_profile_gui.itemlist_profiles.add_item(p["name"])
		account_n_profile_gui.itemlist_profiles_data.append(p["id"])
	

func _on_profile_list_item_selected(index):
	if await set_profile(account_n_profile_gui.itemlist_profiles_data[index]):
		account_n_profile_gui.label_profile.text = "[center]Current Profile: %s" % profile_name






func _on_join_pressed():
	var server_url: String = (await Database.get_records("hosts"))[0]["url"]
	var server_address = server_url.rsplit(":", false, 1)[0].trim_prefix("http://").trim_prefix("https://")
	var server_port = server_url.rsplit(":", false, 1)[1].to_int()
	
	await start(server_address, server_port)


func client_print(args):
	print("[CLIENT|%d] " % multiplayer.get_unique_id(), args)

func start(address: String, port: int):
	if not user_record_id:
		print_debug("not logged in")
		return
	
	
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	enet_peer.create_client(address, port)
	multiplayer.multiplayer_peer = enet_peer
	await multiplayer.connected_to_server
	
	Server.connect_player.rpc_id(1, multiplayer.get_unique_id(), user_username, user_password, profile_record_id)
	client_print("connecting to %s on port %d" % [address, port])
	
	
	client_print("joining world")
	
	account_n_profile_gui.visible = false
	
	player_gui = preload("res://gui/gui.tscn").instantiate()
	World.add_child(player_gui)
	
	
	await setup_standart_inventory(hotbar_gui, "hotbar")
	hotbar_gui.connect("itemslot_selected", func(i): 
		for n in range(hotbar_gui.get_child_count()):
			if n != i:
				hotbar_gui.get_child(n).texture_normal = preload("res://gui/itemslot.png")
				hotbar_gui.get_child(n).z_index = 0
		hotbar_gui.get_child(i).texture_normal = preload("res://gui/itemslot_selected.png")
		hotbar_gui.get_child(i).z_index = 1
	)
	hotbar_gui.visible = true
	await setup_standart_inventory(inventory_gui, "inventory")
	await Database.subscribe("player_profiles/%s" % profile_record_id, "*", func(_r): load_limbo_item(_r.inventories.limbo))
	load_limbo_item((await Server.get_profile_data(profile_record_id)).inventories.limbo)
	
	
	

func _on_server_disconnected():
	client_print("disconnected from server")

@rpc
func assign_player(node_path: NodePath):
	player = get_node(node_path)
	Camera.reparent(player)
	player_gui.player = player


# TODO: adjust for ping and dynamic velocity, perhaps make a whole new component specialized for position synchronization
func predict_client_position(position_client: Vector2, position_server: Vector2, average_velocity: int, max_difference: int):
	if position_client.distance_to(position_server) > max_difference or position_client.distance_to(position_server) < 1:
		return position_server
	else:
		return position_client.lerp(position_server, clamp(average_velocity / position_client.distance_to(position_server), 0, 1))


func load_limbo_item(limbo):
	if "0" in limbo:
		limbo_gui.get_node("TextureRect").texture = Items.data[limbo["0"].item.name].texture
		limbo_gui.get_node("RichTextLabel").text = "%d" % limbo["0"].stack if limbo["0"].stack > 1 else ""
	else:
		limbo_gui.get_node("TextureRect").texture = null
		limbo_gui.get_node("RichTextLabel").text = ""


func setup_standart_inventory(node: Node, inventory_name: String):
	var load_item_textures = func(inventory):
		for k in Inventories.data[inventory_name]:
			if not k in inventory:
				node.get_child(int(k)).get_node("TextureRect").texture = null
				node.get_child(int(k)).get_node("RichTextLabel").text = ""
				continue
			
			node.get_child(int(k)).get_node("TextureRect").texture = Items.data[inventory[k].item.name].texture
			node.get_child(int(k)).get_node("RichTextLabel").text = "%d" % inventory[k].stack if inventory[k].stack > 1 else ""
	
	await Database.subscribe("player_profiles/%s" % profile_record_id, "*", func(r): load_item_textures.call(r.inventories[inventory_name]))
	load_item_textures.call((await Server.get_profile_data(profile_record_id)).inventories[inventory_name])
	
	node.connect("itemslot_selected", func(i): 
		var inventories = (await Server.get_profile_data(profile_record_id)).inventories
		var inventory = inventories[inventory_name]
		var limbo = inventories.limbo
		
		match ["0" in limbo, str(i) in inventory]:
			[false, true]:
				Server.move_inventory_item.rpc_id(1, profile_record_id, inventory_name, str(i), "limbo", "0")
			[true, true]:
				if limbo["0"].item.name == inventory[str(i)].item.name:
					Server.move_inventory_item.rpc_id(1, profile_record_id, "limbo", "0", inventory_name, str(i))
				else:
					Server.swap_inventory_item.rpc_id(1, profile_record_id, inventory_name, str(i), "limbo", "0")
			[true, false]:
				Server.move_inventory_item.rpc_id(1, profile_record_id, "limbo", "0", inventory_name, str(i))
		
		# we do a little predict
		match ["0" in limbo, str(i) in inventory]:
			[false, true]:
				limbo_gui.get_node("TextureRect").texture = Items.data[inventory[str(i)].item.name].texture
				limbo_gui.get_node("RichTextLabel").text = "%d" % inventory[str(i)].stack if inventory[str(i)].stack > 1 else ""
				node.get_child(i).get_node("TextureRect").texture = null
				node.get_child(i).get_node("RichTextLabel").text = ""
			[true, true]:
				if limbo["0"].item.name != inventory[str(i)].item.name:
					limbo_gui.get_node("TextureRect").texture = Items.data[inventory[str(i)].item.name].texture
					limbo_gui.get_node("RichTextLabel").text = "%d" % inventory[str(i)].stack if inventory[str(i)].stack > 1 else ""
					node.get_child(i).get_node("TextureRect").texture = Items.data[limbo["0"].item.name].texture
					node.get_child(i).get_node("RichTextLabel").text = "%d" % limbo["0"].stack if limbo["0"].stack > 1 else ""
				else:
					var _movable_stacks = maxf(floorf(Inventories.data[inventory_name][str(i)].capacity / Items.data[inventory[str(i)].item.name].slot_size - inventory[str(i)].stack), 0)
					if _movable_stacks >= limbo["0"].stack:
						limbo_gui.get_node("RichTextLabel").text = ""
						limbo_gui.get_node("TextureRect").texture = null
					else:
						limbo_gui.get_node("RichTextLabel").text = "%d" % (limbo["0"].stack - _movable_stacks) if (limbo["0"].stack - _movable_stacks) > 1 else ""
					node.get_child(i).get_node("RichTextLabel").text = "%d" % (inventory[str(i)].stack + _movable_stacks)
			[true, false]:
				limbo_gui.get_node("TextureRect").texture = null
				limbo_gui.get_node("RichTextLabel").text = ""
				node.get_child(i).get_node("TextureRect").texture = Items.data[limbo["0"].item.name].texture
				node.get_child(i).get_node("RichTextLabel").text = "%d" % limbo["0"].stack if limbo["0"].stack > 1 else ""
	)
	node.connect("itemslot_mouse_entered", func(i):
		node.get_child(i).get_node("TextureRect2").texture = preload("res://gui/itemslot_hover_overlay.png")
	)
	node.connect("itemslot_mouse_exited", func(i):
		node.get_child(i).get_node("TextureRect2").texture = null
	)
