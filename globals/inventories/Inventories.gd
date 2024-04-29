extends Node


var data = {
	"hotbar": {
		"0": { "capacity": 16 },
		"1": { "capacity": 16 },
		"2": { "capacity": 16 },
		"3": { "capacity": 16 },
		"4": { "capacity": 16 },
		"5": { "capacity": 16 },
		"6": { "capacity": 16 },
		"7": { "capacity": 16 },
	},
	"inventory": {
		"0": { "capacity": 16 },
		"1": { "capacity": 16 },
		"2": { "capacity": 16 },
		"3": { "capacity": 16 },
		"4": { "capacity": 16 },
		"5": { "capacity": 16 },
		"6": { "capacity": 16 },
		"7": { "capacity": 16 },
		"8": { "capacity": 16 },
		"9": { "capacity": 16 },
		"10": { "capacity": 16 },
		"11": { "capacity": 16 },
		"12": { "capacity": 16 },
		"13": { "capacity": 16 },
		"14": { "capacity": 16 },
		"15": { "capacity": 16 },
		"16": { "capacity": 16 },
		"17": { "capacity": 16 },
		"18": { "capacity": 16 },
		"19": { "capacity": 16 },
		"20": { "capacity": 16 },
		"21": { "capacity": 16 },
		"22": { "capacity": 16 },
		"23": { "capacity": 16 },
		"24": { "capacity": 16 },
		"25": { "capacity": 16 },
		"26": { "capacity": 16 },
		"27": { "capacity": 16 },
		"28": { "capacity": 16 },
		"29": { "capacity": 16 },
		"30": { "capacity": 16 },
		"31": { "capacity": 16 },
	},
	"limbo": {
		"0": { "capacity": 69420 }
	}
}


func get_total_slot_space(item_id, inventory_id, slot_id):
	return floor(data[inventory_id][slot_id].capacity / Items.data[item_id].slot_size)


func get_available_slot_space(inventories, item_id, inventory_id, slot_id):
	if not slot_id in inventories[inventory_id]:
		return get_total_slot_space(item_id, inventory_id, slot_id)
	elif item_id != inventories[inventory_id][slot_id].item.type:
		return 0
	else:
		var val = get_total_slot_space(item_id, inventory_id, slot_id) - inventories[inventory_id][slot_id].stack
		assert(val >= 0, "uhm.. slot is overfilled, idk")
		return val


func push_slot_A_to_B(inventories, inventory_A_id, slot_A_id, inventory_B_id, slot_B_id, amount = null):
	assert(amount == null or amount > 0, "r u sure :o?")
	var slot_A = inventories[inventory_A_id][slot_A_id]
	if not slot_B_id in inventories[inventory_B_id]:
		var available_slot_B_space = get_total_slot_space(slot_A.item.type, inventory_B_id, slot_B_id)
		assert(amount == null or (amount <= available_slot_B_space and amount <= slot_A.stack), "sus")
		if available_slot_B_space > 0:
			inventories[inventory_B_id][slot_B_id] = {
				"item": slot_A.item.duplicate(true),
				"stack": min(available_slot_B_space, slot_A.stack) if amount == null else amount
			}
			slot_A.stack -= min(available_slot_B_space, slot_A.stack) if amount == null else amount
	else:
		var slot_B = inventories[inventory_B_id][slot_B_id]
		var available_slot_B_space = get_available_slot_space(inventories, slot_B.item.type, inventory_B_id, slot_B_id)
		assert(amount == null or (amount <= available_slot_B_space and amount <= slot_A.stack), "sus")
		
		slot_B.stack += min(available_slot_B_space, slot_A.stack) if amount == null else amount
		slot_A.stack -= min(available_slot_B_space, slot_A.stack) if amount == null else amount
	
	if inventories[inventory_A_id][slot_A_id].stack == 0:
		inventories[inventory_A_id].erase(slot_A_id)

func swap_slot_A_with_B(inventories, inventory_A_id, slot_A_id, inventory_B_id, slot_B_id):
	var old_slot_A = inventories[inventory_A_id][slot_A_id].duplicate(true)
	inventories[inventory_A_id][slot_A_id] = inventories[inventory_B_id][slot_B_id].duplicate(true)
	inventories[inventory_B_id][slot_B_id] = old_slot_A.duplicate(true)




