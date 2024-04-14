extends Node


var enet_peer = ENetMultiplayerPeer.new()
var gui: CanvasLayer
var player: CharacterBody2D


@onready var account_n_profile_gui: ColorRect = $"/root/main/GUI/AccountNProfileManagment"
@onready var inventory_gui: GridContainer = $"/root/main/GUI/Inventory"
@onready var hotbar_gui: GridContainer = $"/root/main/GUI/Hotbar"


var user_record_id: String
var user_username: String
var user_password: String
var user_authtoken: String
var profile_record_id: String
var profile_name: String
var profile_data: Dictionary

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
	profile_data = profile["json"]
	
	config.set_value("client", "profile", id)
	config.save("user://config.cfg")
	
	return true


func _on_create_profile_pressed():
	var new_profile_name = account_n_profile_gui.input_new_profile_name.text
	
	var new_profile = await Database.create_record("player_profiles", {
		"user": user_record_id,
		"name": new_profile_name,
		"json": {
			"player_type": ["square", "widesquare", "triangle"].pick_random()
		}
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
	
	hotbar_gui.connect("itemslot_selected", func(index): print(index))
	hotbar_gui.visible = true
	
	gui = preload("res://gui/gui.tscn").instantiate()
	World.add_child(gui)
	

func _on_server_disconnected():
	client_print("disconnected from server")

@rpc
func assign_player(node_path: NodePath):
	player = get_node(node_path)
	Camera.reparent(player)
	gui.player = player
	
	await Database.subscribe("player_profiles/%s" % profile_record_id, "*", func(_r): load_hotbar_item_textures())
	load_hotbar_item_textures()
	
	await Database.subscribe("player_profiles/%s" % profile_record_id, "*", func(_r): load_inventory_item_textures())
	load_inventory_item_textures()


# TODO: adjust for ping and dynamic velocity, perhaps make a whole new component specialized for position synchronization
func predict_client_position(position_client: Vector2, position_server: Vector2, average_velocity: int, max_difference: int):
	if position_client.distance_to(position_server) > max_difference:
		return position_server
	else:
		return position_client.lerp(position_server, clamp(average_velocity / position_client.distance_to(position_server), 0, 1))


func load_hotbar_item_textures():
	var items = (await Database.get_record("player_profiles", profile_record_id))["json"]["items"].filter(func(item): return item.inventory_name == "hotbar")
	for n in range(hotbar_gui.get_child_count()):
		var fitting_items = items.filter(func(item): return item.slot == n)
		if fitting_items.is_empty():
			hotbar_gui.get_child(n).get_child(0).texture = null
			hotbar_gui.get_child(n).get_child(1).text = ""
			return
		
		assert(fitting_items.all(func(item): return item.item_data.name == fitting_items[0].item_data.name), "multiple different items >>%s<< are trying to fit into single hotbar slot" % JSON.stringify(fitting_items))
		hotbar_gui.get_child(n).get_child(0).texture = ItemDisplayTextures.data[fitting_items[0].item_data.name]
		hotbar_gui.get_child(n).get_child(1).text = "%d" % fitting_items.size() if fitting_items.size() > 1 else ""


func load_inventory_item_textures():
	var items = (await Database.get_record("player_profiles", profile_record_id))["json"]["items"].filter(func(item): return item.inventory_name == "inventory")
	for n in range(inventory_gui.get_child_count()):
		var fitting_items = items.filter(func(item): return item.slot == n)
		if fitting_items.is_empty():
			inventory_gui.get_child(n).get_child(0).texture = null
			inventory_gui.get_child(n).get_child(1).text = ""
			return
		
		assert(fitting_items.all(func(item): return item.item_data.name == fitting_items[0].item_data.name), "multiple different items >>%s<< are trying to fit into single inventory slot" % JSON.stringify(fitting_items))
		inventory_gui.get_child(n).get_child(0).texture = ItemDisplayTextures.data[fitting_items[0].item_data.name]
		inventory_gui.get_child(n).get_child(1).text = "%d" % fitting_items.size() if fitting_items.size() > 1 else ""

