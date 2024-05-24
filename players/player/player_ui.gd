extends CanvasLayer


@onready var player = $"../"
@onready var inventory_ui = $"Inventory"
@onready var hotbar_ui = $"Hotbar"
@onready var all_slots = inventory_ui.get_children() + hotbar_ui.get_children()

var action_slot_id


func _ready():
	for n in range(all_slots.size()):
		all_slots[n].pressed.connect(func():
			_on_slot_pressed(str(n))
		)
	


func _process(_delta):
	if player.inventory == null: return
	for n in range(player.inventory.values().size()):
		var slot = player.inventory.values()[n]
		if n < 8:
			hotbar_ui.get_child(n).display_slot(slot)
		else:
			inventory_ui.get_child(n - 8).display_slot(slot)
	


func _on_slot_pressed(slot_id):
	if action_slot_id == null:
		if player.inventory[slot_id].item_id != null:
			action_slot_id = slot_id
		return
	
	match [player.inventory[action_slot_id].item_id != null, player.inventory[slot_id].item_id != null]:
		[true, false]:
			player.do_action_slot.rpc_id(1, action_slot_id, slot_id)
	action_slot_id = null


func _on_open_inventory_pressed():
	inventory_ui.visible = not inventory_ui.visible
