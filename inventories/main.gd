extends Node


@export var world: Node
var inventories = {}
var savefile = null


func _ready():
	if world.name == "Server":
		savefile = world.world_dir.path_join("inventories.cfg")
		if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
		world.load_queued.connect(_load_inventories)
		world.save_queued.connect(_save_inventories)


func _PRINT_STAMP(s: String):
	print("[%s][%s] %s" % [name, Time.get_time_string_from_system(), s])


func _save_inventories():
	var f = ConfigFile.new()
	for i in inventories:
		for s in inventories[i]:
			f.set_value(i, s, {
				"stack": inventories[i][s].stack,
				"capacity": inventories[i][s].capacity,
				"item_id": inventories[i][s].item_id,
			})
	if f.save(savefile) != OK: push_error("couldn't save %s" % savefile); return
	_PRINT_STAMP("saved inventories")


func _load_inventories():
	if not inventories.is_empty(): push_error("inventories is not empty"); return
	var f = ConfigFile.new()
	if f.load(savefile) != OK: push_error("couldn't load %s" % savefile); return
	for section in f.get_sections():
		inventories[section] = {}
		for key in f.get_section_keys(section):
			inventories[section][key] = {
				"stack": f.get_value(section, key).stack,
				"capacity": f.get_value(section, key).capacity,
				"item_id": f.get_value(section, key).item_id,
			}
	_PRINT_STAMP("loaded inventories")


func create_default_inventory(slot_count: int):
	var inventory_id = "0"
	while inventories.has(inventory_id):
		inventory_id = str(int(inventory_id) + 1)
	
	inventories[inventory_id] = {}
	for i in range(slot_count):
		inventories[inventory_id]["slot%d" % i] = {
			"stack": null,
			"capacity": 16.0,
			"item_id": null,
		}
	return inventory_id


func push_item_to_slot(item: Node, inventory_id: String, slot_id: String):
	if not inventories.has(inventory_id): push_error("couldn't find inventory %s" % inventory_id); return
	if not inventories[inventory_id].has(slot_id): push_error("couldn't find slot %s in inventory %s" % [slot_id, inventory_id]); return
	
	var pushable_count = get_pushable_count(item.stack, item.id, inventories[inventory_id][slot_id].stack, inventories[inventory_id][slot_id].capacity, inventories[inventory_id][slot_id].item_id)
	if pushable_count > 0 and inventories[inventory_id][slot_id].item_id == null:
		inventories[inventory_id][slot_id].stack = 0
		inventories[inventory_id][slot_id].item_id = item.id
	item.stack -= pushable_count
	inventories[inventory_id][slot_id].stack += pushable_count
	return pushable_count


func push_slot_to_slot(inventory_a, slot_a, inventory_b, slot_b):
	if not inventories.has(inventory_a): push_error("couldn't find inventory_a %s" % inventory_a); return
	if not inventories[inventory_a].has(slot_a): push_error("couldn't find slot %s in inventory_a %s" % [slot_a, inventory_a]); return
	if not inventories.has(inventory_b): push_error("couldn't find inventory_b %s" % inventory_b); return
	if not inventories[inventory_b].has(slot_b): push_error("couldn't find slot %s in inventory_b %s" % [slot_b, inventory_b]); return
	
	var sa = inventories[inventory_a][slot_a]
	var sb = inventories[inventory_b][slot_b]
	var pushable_count = get_pushable_count(sa.stack, sa.item_id, sb.stack, sb.capacity, sb.item_id)
	if pushable_count > 0 and sb.item_id == null:
		sb.stack = 0
		sb.item_id = sa.item_id
	sa.stack -= pushable_count
	sb.stack += pushable_count
	return pushable_count


func push_item_to_inventory(item: Node, inventory_id: String):
	if not inventories.has(inventory_id): push_error("couldn't find inventory %s" % inventory_id); return
	var pushed_stacks = 0
	for slot_id in inventories[inventory_id]:
		pushed_stacks += push_item_to_slot(item, inventory_id, slot_id)
		if item.stack <= 0:
			break
	
	return pushed_stacks


func push_slot_to_inventory(inventory_a, slot_a, inventory_b): 
	if not inventories.has(inventory_a): push_error("couldn't find inventory_a %s" % inventory_a); return
	if not inventories[inventory_a].has(slot_a): push_error("couldn't find slot %s in inventory_a %s" % [slot_a, inventory_a]); return
	if not inventories.has(inventory_b): push_error("couldn't find inventory_b %s" % inventory_b); return
	
	var pushed_stacks = 0
	for slot_b in inventories[inventory_b]:
		pushed_stacks += push_slot_to_slot(inventory_a, slot_a, inventory_b, slot_b)
		if inventories[inventory_a][slot_a].stack <= 0:
			inventories[inventory_a][slot_a].stack = null
			inventories[inventory_a][slot_a].item_id = null
			break
	
	return pushed_stacks


func get_pushable_count(stack_a, id_a, stack_b, capacity_b, id_b):
	if not $"../Items".config.has(id_a): push_error("couldn't find item %s" % id_a); return
	if id_b == null:
		return min(floor(capacity_b / $"../Items".config[id_a].size), stack_a)
	elif id_b != id_a:
		return 0
	elif id_b == id_a:
		return min(floor(capacity_b / $"../Items".config[id_a].size) - stack_b, stack_a)
	
	push_error("wtf?!")
