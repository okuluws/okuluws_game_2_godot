extends Node2D


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	for node: Area2D in ($"AttractionArea" as Area2D).get_overlapping_areas():
		
		if "is_player_pickupable" in node and node.get("is_player_pickupable") == true:
			node.global_position = node.global_position.lerp(global_position, 0.1)


func _on_pickup_area_area_entered(body: Area2D) -> void:
	if not multiplayer.is_server():
		return
	
	if "is_player_pickupable" in body and body.get("is_player_pickupable") == true:
		return
	
	#body.visible = false
	#if await Server.try_item_fit_inventories(Server.players[owner.user_record_id]["profile_record_id"], body.data, ["hotbar", "inventory"]):
		#body.queue_free()
		#return

