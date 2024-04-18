extends Node2D


func _physics_process(_delta):
	if not multiplayer.is_server():
		return
	
	for node: Area2D in $"AttractionArea".get_overlapping_areas():
		if "is_player_pickupable" in node and node.is_player_pickupable:
			node.global_position = node.global_position.lerp(global_position, 0.1)


func _on_pickup_area_area_entered(body):
	if not multiplayer.is_server():
		return
	
	if not ("is_player_pickupable" in body and body.is_player_pickupable):
		return
	
	body.visible = false
	await Server.update_profile_entry(Server.players[owner.user_record_id]["profile_record_id"], "inventories", func(inventories):
		for k in Inventories.data.hotbar:
			if not k in inventories.hotbar:
				inventories.hotbar[k] = {
					"item": body.data,
					"stack": 1
				}
				body.queue_free()
				return inventories
			
			if inventories.hotbar[k].item.name == body.data.name and Items.data[body.data.name].slot_size * (inventories.hotbar[k].stack + 1) <= Inventories.data.hotbar[k].capacity:
				inventories.hotbar[k].stack += 1
				body.queue_free()
				return inventories
		
		
		for k in Inventories.data.inventory:
			if not k in inventories.inventory:
				inventories.inventory[k] = {
					"item": body.data,
					"stack": 1
				}
				body.queue_free()
				return inventories
			
			if inventories.inventory[k].item.name == body.data.name and Items.data[body.data.name].slot_size * (inventories.inventory[k].stack + 1) <= Inventories.data.inventory[k].capacity:
				inventories.inventory[k].stack += 1
				body.queue_free()
				return inventories
		
		return inventories
	)
