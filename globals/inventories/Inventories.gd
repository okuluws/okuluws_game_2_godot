#extends Node
#
#
#var config = {
	#"hotbar": {
		#"slot_count": 8,
		#"slot_capacity": 16
	#},
	#"inventory": {
		#"slot_count": 32,
		#"slot_capacity": 16
	#},
	#"limbo": {
		#"slot_count": 1,
		#"slot_capacity": 69420
	#}
#}
#
#
#func get_total_slot_space(item_type_id, inventory_type_id):
	#return floor(config[inventory_type_id].slot_capacity / Items.config[item_type_id].slot_size)
#
#
#func get_available_slot_space(inventories, item_type_id, inventory_uid, slot_uid):
	#var inventory = inventories[inventory_uid]
	#if not slot_uid in inventory.slots:
		#return get_total_slot_space(item_type_id, inventory.type_id)
	#elif item_type_id != inventory.slots[slot_uid].item.type_id:
		#return 0
	#else:
		#var val = get_total_slot_space(item_type_id, inventory.type_id) - inventory.slots[slot_uid].stack
		#assert(val >= 0, "uhm.. slot is overfilled, idk")
		#return val
#
#
#func push_slot_A_to_B(inventories, inventory_A_uid, slot_A_uid, inventory_B_uid, slot_B_uid, amount = null):
	#assert(amount == null or amount > 0, "r u sure :o?")
	#var inventory_A = inventories[inventory_A_uid]
	#var inventory_B = inventories[inventory_B_uid]
	#var slot_A = inventory_A.slots[slot_A_uid]
	#if not slot_B_uid in inventory_B.slots:
		#var available_slot_B_space = get_total_slot_space(slot_A.item.type_id, inventory_B.type_id)
		#assert(amount == null or (amount <= available_slot_B_space and amount <= slot_A.stack), "sus")
		#if available_slot_B_space > 0:
			#inventories[inventory_B_uid].slots[slot_B_uid] = {
				#"item": slot_A.item.duplicate(true),
				#"stack": min(available_slot_B_space, slot_A.stack) if amount == null else amount
			#}
			#slot_A.stack -= min(available_slot_B_space, slot_A.stack) if amount == null else amount
	#else:
		#var slot_B = inventory_B.slots[slot_B_uid]
		#var available_slot_B_space = get_available_slot_space(inventories, slot_B.item.type_id, inventory_B_uid, slot_B_uid)
		#assert(amount == null or (amount <= available_slot_B_space and amount <= slot_A.stack), "sus")
		#
		#slot_B.stack += min(available_slot_B_space, slot_A.stack) if amount == null else amount
		#slot_A.stack -= min(available_slot_B_space, slot_A.stack) if amount == null else amount
	#
	#if inventory_A.slots[slot_A_uid].stack == 0:
		#inventory_A.slots.erase(slot_A_uid)
#
#
#func swap_slot_A_with_B(inventories, inventory_A_uid, slot_A_uid, inventory_B_uid, slot_B_uid):
	#var old_slot_A = inventories[inventory_A_uid].slots[slot_A_uid].duplicate(true)
	#inventories[inventory_A_uid].slots[slot_A_uid] = inventories[inventory_B_uid].slots[slot_B_uid].duplicate(true)
	#inventories[inventory_B_uid].slots[slot_B_uid] = old_slot_A.duplicate(true)
#
#
#
