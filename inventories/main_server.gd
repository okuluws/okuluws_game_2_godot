extends Node


@onready var server = $"../"
@onready var savefile = server.world_dir.path_join("inventories.cfg")
@onready var items_common = server.get_node("Items/Common")
var inventories = {}


func _ready():
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	server.load_queued.connect(_load_inventories)
	server.save_queued.connect(_save_inventories)


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
	server.log_default("saved inventories")


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
	server.log_default("loaded inventories")


func create_default_inventory(slot_count: int):
	var inventory_id = "0"
	while inventories.has(inventory_id):
		inventory_id = str(int(inventory_id) + 1)
	
	inventories[inventory_id] = {}
	for i in range(slot_count):
		inventories[inventory_id]["%d" % i] = {
			"stack": 0,
			"capacity": 64.0,
			"item_id": null,
		}
	return inventory_id


func add_stack_to_slot(inventory_id, slot_id, amount):
	if _ERR_SLOT_EXISTS(inventory_id, slot_id): return
	inventories[inventory_id][slot_id].stack += amount
	if inventories[inventory_id][slot_id].stack <= 0:
		inventories[inventory_id][slot_id].item_id = null


func push_item_to_slot(item: Node, inventory_id: String, slot_id: String):
	if _ERR_SLOT_EXISTS(inventory_id, slot_id): return
	if item.id == null: return 0
	var s = inventories[inventory_id][slot_id]
	var pushable_count = get_pushable_count(item.stack, item.id, s.stack, s.capacity, s.item_id)
	if pushable_count > 0:
		if s.item_id == null: s.item_id = item.id; s.stack = 0
		s.stack += pushable_count
		item.stack -= pushable_count
		if item.stack <= 0: item.despawn()
	return pushable_count


func push_slot_to_slot(inventory_a, slot_a, inventory_b, slot_b):
	if _any_true([_ERR_SLOT_EXISTS(inventory_a, slot_a), _ERR_SLOT_EXISTS(inventory_b, slot_b)]): return
	var sa = inventories[inventory_a][slot_a]
	var sb = inventories[inventory_b][slot_b]
	if sa.item_id == null: return 0
	var pushable_count = get_pushable_count(sa.stack, sa.item_id, sb.stack, sb.capacity, sb.item_id)
	if pushable_count > 0:
		if sb.item_id == null: sb.item_id = sa.item_id; sb.stack = 0
		sb.stack += pushable_count
		sa.stack -= pushable_count
		if sa.stack <= 0: sa.item_id = null
	return pushable_count


func push_item_to_inventory(item: Node, inventory_id: String):
	if _ERR_INVENTORY_EXISTS(inventory_id): return
	if item.id == null: return 0
	var pushed_stacks = 0
	for slot_id in inventories[inventory_id]:
		if item.stack <= 0:
			break
		pushed_stacks += push_item_to_slot(item, inventory_id, slot_id)
	return pushed_stacks


func push_slot_to_inventory(inventory_a, slot_a, inventory_b):
	if _any_true([_ERR_SLOT_EXISTS(inventory_a, slot_a), _ERR_INVENTORY_EXISTS(inventory_b)]): return
	var sa = inventories[inventory_a][slot_a]
	if sa.item_id == null: return 0
	var pushed_stacks = 0
	for slot_b in inventories[inventory_b]:
		if sa.stack <= 0:
			break
		pushed_stacks += push_slot_to_slot(inventory_a, slot_a, inventory_b, slot_b)
	return pushed_stacks


func get_pushable_count(stack_a, id_a, stack_b, capacity_b, id_b):
	if not items_common.config.has(id_a): push_error("couldn't find item %s" % id_a); return
	if id_b == null:
		return min(floor(capacity_b / items_common.config[id_a].size), stack_a)
	elif id_b != id_a:
		return 0
	elif id_b == id_a:
		return min(floor(capacity_b / items_common.config[id_a].size) - stack_b, stack_a)
	
	push_error("wtf?!")


func _ERR_INVENTORY_EXISTS(inventory_id):
	if not inventories.has(inventory_id): push_error("couldn't find inventory %s" % inventory_id); return true
	return false


func _ERR_SLOT_EXISTS(inventory_id, slot_id):
	if not inventories.has(inventory_id): push_error("couldn't find inventory %s" % inventory_id); return true
	elif not inventories[inventory_id].has(slot_id): push_error("couldn't find slot %s in inventory %s" % [slot_id, inventory_id]); return true
	return false


func _any_true(arr: Array):
	return arr.any(func(b): return b == true)


