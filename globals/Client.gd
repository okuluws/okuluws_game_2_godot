extends Node


@onready var World = $"/root/Main/World"


func start(full_server_address: String):
	print("Starting Client...")
	
	var server_address = full_server_address.get_slice(":", 0)
	var server_port = int(full_server_address.get_slice(":", 1))
	
	var enet = ENetMultiplayerPeer.new()
	enet.create_client(server_address, server_port)
	multiplayer.multiplayer_peer = enet
	
	multiplayer.connected_to_server.connect(func(): print("connected to server peer"))
	


@rpc
func assign_player(node_name: String):
	await get_tree().create_timer(0.1).timeout
	World.get_node(node_name).add_child(Camera2D.new())

#
#var enet_peer = ENetMultiplayerPeer.new()
#var player_gui: CanvasLayer
#var player: CharacterBody2D
#
#@onready var account_n_profile_gui: ColorRect = $"/root/main/GUI/AccountNProfileManagment"
#@onready var inventory_gui: GridContainer = $"/root/main/GUI/Inventory"
#@onready var hotbar_gui: GridContainer = $"/root/main/GUI/Hotbar"
#@onready var limbo_node = $"/root/main/GUI/Limbo"
#
#const CONFIG_FILEPATH = "user://client.cfg"
#var profile_id: FuncU.ConfigFileSyncedValue
#var profile_name: FuncU.ConfigFileSyncedValue
#
#signal start_finished
#
#
#func _ready():
	#profile_id = FuncU.ConfigFileSyncedValue.new(CONFIG_FILEPATH, "", "profile_id", "")
	#profile_name = FuncU.ConfigFileSyncedValue.new(CONFIG_FILEPATH, "", "profile_name", "")
	#if Pocketbase.authtoken.value != "":
		#await Pocketbase.refresh_authtoken("users")
		#update_current_user_gui()
		#await update_profiles_list_gui()
	#
	#if profile_name.value != "":
		#update_selected_profile_gui()
	#
	#account_n_profile_gui.get_node("Login").connect("pressed", _on_login_pressed)
	#account_n_profile_gui.get_node("CreateProfile").connect("pressed", _on_create_profile_pressed)
	#account_n_profile_gui.get_node("ProfileList").connect("item_selected", _on_profile_list_item_selected)
	#account_n_profile_gui.get_node("Join").connect("pressed", _on_join_pressed)
#
#
#func update_profiles_list_gui():
	#account_n_profile_gui.itemlist_profiles.clear()
	#account_n_profile_gui.itemlist_profiles_data.clear()
	#
	#var res = await Pocketbase.get_records("player_profiles", "?filter=(user.id='%s')" % Pocketbase.user_id.value)
	#if res.code == 200:
		#for p in res.data:
			#account_n_profile_gui.itemlist_profiles.add_item(p.name)
			#account_n_profile_gui.itemlist_profiles_data.append(p.id)
#
#func update_selected_profile_gui():
	#account_n_profile_gui.label_profile.text = "[center]Current Profile: %s" % profile_name.value
#
#func update_current_user_gui():
	#account_n_profile_gui.label_user.text = "[center]Logged in as %s" % Pocketbase.username.value
#
#func _on_login_pressed():
	#var res = await Pocketbase.auth_w_password("users", account_n_profile_gui.input_username.text, account_n_profile_gui.input_password.text)
	#if res.code == 200:
		#update_current_user_gui()
	#else:
		#print_debug("failed to login")
	#
	#await update_profiles_list_gui()
#
#
#func _on_create_profile_pressed():
	#var new_profile_name = account_n_profile_gui.input_new_profile_name.text
	#
	#var res = await Pocketbase.create_record("player_profiles", {
		#"user": Pocketbase.user_id.value,
		#"name": new_profile_name,
		#"player_type": ["square", "widesquare", "triangle"].pick_random()
	#})
	#if res.code != 200:
		#print_debug("couldn't create profile")
		#return
	#
	#await update_profiles_list_gui()
#
#
#func _on_profile_list_item_selected(index):
	#var res = await Pocketbase.get_record("player_profiles", account_n_profile_gui.itemlist_profiles_data[index])
	#if not res.code == 200:
		#print_debug("selected invalid profile")
		#return
	#
	#
	#profile_id.value = res.data.id
	#profile_name.value = res.data.name
	#update_selected_profile_gui()
#
#
#func _on_join_pressed():
	#var res = await Pocketbase.get_records("hosts")
	#if res.code != 200:
		#print_debug("no available servers found ;(")
		#return
	#
	#var server_url: String = res.data[0]["url"]
	#var server_address = server_url.rsplit(":", false, 1)[0].trim_prefix("http://").trim_prefix("https://")
	#var server_port = server_url.rsplit(":", false, 1)[1].to_int()
	#
	#await start(server_address, server_port)
#
#
#
#
#
#
#func client_print(args):
	#print("[CLIENT|%d] " % multiplayer.get_unique_id(), args)
#
#func start(address: String, port: int):
	#if Pocketbase.authtoken.value == "":
		#print_debug("not logged in")
		#return
	#
	#
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	#
	#enet_peer.create_client(address, port)
	#multiplayer.multiplayer_peer = enet_peer
	#await multiplayer.connected_to_server
	#
	#Server.connect_player.rpc_id(1, multiplayer.get_unique_id(), Pocketbase.authtoken.value, profile_id.value)
	#client_print("connecting to %s on port %d" % [address, port])
	#
	#
	#client_print("joining world")
	#
	#account_n_profile_gui.visible = false
	#
	#player_gui = preload("res://gui/gui.tscn").instantiate()
	#World.add_child(player_gui)
	#
	#
	#await setup_standart_inventory(hotbar_gui, "hotbar")
	#hotbar_gui.connect("itemslot_left_click", func(i): 
		#for n in range(hotbar_gui.get_child_count()):
			#if n != i:
				#hotbar_gui.get_child(n).texture_normal = preload("res://gui/itemslot.png")
				#hotbar_gui.get_child(n).z_index = 0
		#hotbar_gui.get_child(i).texture_normal = preload("res://gui/itemslot_selected.png")
		#hotbar_gui.get_child(i).z_index = 1
	#)
	#hotbar_gui.visible = true
	#await setup_standart_inventory(inventory_gui, "inventory")
	#await Pocketbase.subscribe("player_profiles/%s" % profile_id.value, "*", func(_profile): limbo_node.update_textures(_profile.inventories.limbo.slots))
	#limbo_node.update_textures((await Server.get_profile_data(profile_id.value)).inventories.limbo.slots)
	#
	#start_finished.emit()
#
#
#
#func _on_server_disconnected():
	#client_print("disconnected from server")
#
#@rpc
#func assign_player(node_path: NodePath):
	#player = get_node(node_path)
	#Camera.reparent(player)
	#player_gui.player = player
#
#
## TODO: adjust for ping and dynamic velocity, perhaps make a whole new component specialized for position synchronization
#func predict_client_position(position_client: Vector2, position_server: Vector2, average_velocity: int, max_difference: int):
	#if position_client.distance_to(position_server) > max_difference or position_client.distance_to(position_server) < 1:
		#return position_server
	#else:
		#return position_client.lerp(position_server, clamp(average_velocity / position_client.distance_to(position_server), 0, 1))
#
#
#func setup_standart_inventory(inventory_node: Node, inventory_id: String):
	#await Pocketbase.subscribe("player_profiles/%s" % profile_id.value, "*", func(_profile): inventory_node.update_textures(_profile.inventories[inventory_id].slots, inventory_id))
	#inventory_node.update_textures((await Server.get_profile_data(profile_id.value)).inventories[inventory_id].slots, inventory_id)
	#
	#inventory_node.connect("itemslot_left_click", func(i): 
		#var inventories = (await Server.get_profile_data(profile_id.value)).inventories
		#match ["0" in inventories.limbo.slots, str(i) in inventories[inventory_id].slots]:
			#[false, true]:
				#Server.move_inventory_item.rpc_id(1, profile_id.value, inventory_id, str(i), "limbo", "0")
				#Inventories.push_slot_A_to_B(inventories, inventory_id, str(i), "limbo", "0")
			#[true, true]:
				#if inventories.limbo.slots["0"].item.type_id == inventories[inventory_id].slots[str(i)].item.type_id:
					#Server.move_inventory_item.rpc_id(1, profile_id.value, "limbo", "0", inventory_id, str(i))
					#Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i))
				#else:
					#Server.swap_inventory_item.rpc_id(1, profile_id.value, inventory_id, str(i), "limbo", "0")
					#Inventories.swap_slot_A_with_B(inventories, inventory_id, str(i), "limbo", "0")
			#[true, false]:
				#Server.move_inventory_item.rpc_id(1, profile_id.value, "limbo", "0", inventory_id, str(i))
				#Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i))
			#
		#inventory_node.update_textures(inventories[inventory_id].slots, inventory_id)
		#limbo_node.update_textures(inventories.limbo.slots)
	#)
	#inventory_node.connect("itemslot_right_click", func(i):
		#var inventories = (await Server.get_profile_data(profile_id.value)).inventories
		#match ["0" in inventories.limbo.slots, str(i) in inventories[inventory_id].slots]:
			#[false, true]:
				#Server.move_inventory_item.rpc_id(1, profile_id.value, inventory_id, str(i), "limbo", "0", ceil(inventories[inventory_id].slots[str(i)].stack / 2))
				#Inventories.push_slot_A_to_B(inventories, inventory_id, str(i), "limbo", "0", ceil(inventories[inventory_id].slots[str(i)].stack / 2))
			#[true, true]:
				#if inventories.limbo["0"].slots.item.type_id == inventories[inventory_id].slots[str(i)].item.type_id:
					#Server.move_inventory_item.rpc_id(1, profile_id.value, "limbo", "0", inventory_id, str(i), 1)
					#Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i), 1)
			#[true, false]:
				#Server.move_inventory_item.rpc_id(1, profile_id.value, "limbo", "0", inventory_id, str(i), 1)
				#Inventories.push_slot_A_to_B(inventories, "limbo", "0", inventory_id, str(i), 1)
			#
		#inventory_node.update_textures(inventories[inventory_id].slots, inventory_id)
		#limbo_node.update_textures(inventories.limbo.slots)
	#)
	#inventory_node.connect("itemslot_mouse_entered", func(i):
		#inventory_node.get_child(i).get_node("TextureRect2").texture = preload("res://gui/itemslot_hover_overlay.png")
	#)
	#inventory_node.connect("itemslot_mouse_exited", func(i):
		#inventory_node.get_child(i).get_node("TextureRect2").texture = null
	#)
	#inventory_node.connect("itemslot_left_click_sweep", func(indexes):
		#print(indexes)
	#)
