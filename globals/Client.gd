extends Node


var enet_peer = ENetMultiplayerPeer.new()
var player_gui: CanvasLayer
var player: CharacterBody2D


@onready var account_n_profile_gui: ColorRect = $"/root/main/GUI/AccountNProfileManagment"
@onready var inventory_gui: GridContainer = $"/root/main/GUI/Inventory"
@onready var hotbar_gui: GridContainer = $"/root/main/GUI/Hotbar"
@onready var limbo_node = $"/root/main/GUI/Limbo"


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
		await fetch_n_update_user_profiles()
	
	account_n_profile_gui.get_node("Login").connect("pressed", _on_login_pressed)
	account_n_profile_gui.get_node("CreateProfile").connect("pressed", _on_create_profile_pressed)
	account_n_profile_gui.get_node("ProfileList").connect("item_selected", _on_profile_list_item_selected)
	account_n_profile_gui.get_node("Join").connect("pressed", _on_join_pressed)



func fetch_n_update_user_profiles():
	account_n_profile_gui.itemlist_profiles.clear()
	account_n_profile_gui.itemlist_profiles_data.clear()
	
	var res = await Pocketbase.collection("player_profiles").records("?filter=(user.id='%s')" % user_record_id)
	if res.code == 200:
		for p in res.data:
			account_n_profile_gui.itemlist_profiles.add_item(p.name)
			account_n_profile_gui.itemlist_profiles_data.append(p.id)


func user_login(username: String, password: String) -> bool:
	var res = await Pocketbase.collection("users").auth(username, password)
	if res.code != 200:
		print_debug("failed to login")
		return false
	
	user_record_id = res.data.record.id
	user_username = username
	user_password = password
	
	config.set_value("client", "username", username)
	config.set_value("client", "password", password)
	config.save("user://config.cfg")
	
	return true


func _on_login_pressed():
	await user_login(account_n_profile_gui.input_username.text, account_n_profile_gui.input_password.text)
	account_n_profile_gui.label_user.text = "[center]Logged in as %s" % user_username
	
	await fetch_n_update_user_profiles()


func set_profile(id: String) -> bool:
	var res = await Pocketbase.collection("player_profiles").record(id)
	if res.code != 200:
		print_debug("profile <%s> not found" % id)
		return false
	
	var profile = res.data
	profile_record_id = profile["id"]
	profile_name = profile["name"]
	
	config.set_value("client", "profile", id)
	config.save("user://config.cfg")
	
	return true


func _on_create_profile_pressed():
	var new_profile_name = account_n_profile_gui.input_new_profile_name.text
	
	var res = await Pocketbase.collection("player_profiles").create({
		"user": user_record_id,
		"name": new_profile_name,
		"player_type": ["square", "widesquare", "triangle"].pick_random()
	})
	if res.code != 200:
		print_debug("couldn't create profile")
		return
	
	await fetch_n_update_user_profiles()


func _on_profile_list_item_selected(index):
	if await set_profile(account_n_profile_gui.itemlist_profiles_data[index]):
		account_n_profile_gui.label_profile.text = "[center]Current Profile: %s" % profile_name


func _on_join_pressed():
	var res = await Pocketbase.collection("hosts").records()
	if res.code != 200:
		print_debug("no available servers found ;(")
		return
	
	var server_url: String = res.data[0]["url"]
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
	hotbar_gui.connect("itemslot_left_click", func(i): 
		for n in range(hotbar_gui.get_child_count()):
			if n != i:
				hotbar_gui.get_child(n).texture_normal = preload("res://gui/itemslot.png")
				hotbar_gui.get_child(n).z_index = 0
		hotbar_gui.get_child(i).texture_normal = preload("res://gui/itemslot_selected.png")
		hotbar_gui.get_child(i).z_index = 1
	)
	hotbar_gui.visible = true
	await setup_standart_inventory(inventory_gui, "inventory")
	await Pocketbase.collection("player_profiles").subscribe(profile_record_id, "*", func(_profile): limbo_node.update_textures(_profile.inventories.limbo))
	limbo_node.update_textures((await Server.get_profile_data(profile_record_id)).inventories.limbo)
	



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


func setup_standart_inventory(inventory_node: Node, inventory_id: String):
	await Pocketbase.collection("player_profiles").subscribe(profile_record_id, "*", func(_profile): inventory_node.update_textures(_profile.inventories[inventory_id], inventory_id))
	inventory_node.update_textures((await Server.get_profile_data(profile_record_id)).inventories[inventory_id], inventory_id)
	
	inventory_node.connect("itemslot_left_click", func(i): 
		var inventories = (await Server.get_profile_data(profile_record_id)).inventories
		match ["0" in inventories.limbo, str(i) in inventories[inventory_id]]:
			[false, true]:
				Server.move_inventory_item.rpc_id(1, profile_record_id, inventory_id, str(i), "limbo", "0")
				Inventories.push_slot_A_to_B(inventories, inventory_id, str(i), "limbo", "0")
			[true, true]:
				if inventories.limbo["0"].item.type == inventories[inventory_id][str(i)].item.type:
					Server.move_inventory_item.rpc_id(1, profile_record_id, "limbo", "0", inventory_id, str(i))
					Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i))
				else:
					Server.swap_inventory_item.rpc_id(1, profile_record_id, inventory_id, str(i), "limbo", "0")
					Inventories.swap_slot_A_with_B(inventories, inventory_id, str(i), "limbo", "0")
			[true, false]:
				Server.move_inventory_item.rpc_id(1, profile_record_id, "limbo", "0", inventory_id, str(i))
				Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i))
			
		inventory_node.update_textures(inventories[inventory_id], inventory_id)
		limbo_node.update_textures(inventories.limbo)
	)
	inventory_node.connect("itemslot_right_click", func(i):
		var inventories = (await Server.get_profile_data(profile_record_id)).inventories
		match ["0" in inventories.limbo, str(i) in inventories[inventory_id]]:
			[false, true]:
				Server.move_inventory_item.rpc_id(1, profile_record_id, inventory_id, str(i), "limbo", "0", ceil(inventories[inventory_id][str(i)].stack / 2))
				Inventories.push_slot_A_to_B(inventories, inventory_id, str(i), "limbo", "0", ceil(inventories[inventory_id][str(i)].stack / 2))
			[true, true]:
				if inventories.limbo["0"].item.type == inventories[inventory_id][str(i)].item.type:
					Server.move_inventory_item.rpc_id(1, profile_record_id, "limbo", "0", inventory_id, str(i), 1)
					Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i), 1)
			[true, false]:
				Server.move_inventory_item.rpc_id(1, profile_record_id, "limbo", "0", inventory_id, str(i), 1)
				Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i), 1)
			
		inventory_node.update_textures(inventories[inventory_id], inventory_id)
		limbo_node.update_textures(inventories.limbo)
	)
	inventory_node.connect("itemslot_mouse_entered", func(i):
		inventory_node.get_child(i).get_node("TextureRect2").texture = preload("res://gui/itemslot_hover_overlay.png")
	)
	inventory_node.connect("itemslot_mouse_exited", func(i):
		inventory_node.get_child(i).get_node("TextureRect2").texture = null
	)
	inventory_node.connect("itemslot_left_click_sweep", func(indexes):
		print(indexes)
	)
