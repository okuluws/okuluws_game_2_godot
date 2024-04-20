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
	if await Server.try_item_fit_inventory(Server.players[owner.user_record_id]["profile_record_id"], body.data, "hotbar"):
		body.queue_free()
		return
	if await Server.try_item_fit_inventory(Server.players[owner.user_record_id]["profile_record_id"], body.data, "inventory"):
		body.queue_free()
		return

