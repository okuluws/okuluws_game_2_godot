extends CanvasLayer


@onready var player = $"../"
@onready var all_slots = $"Hotbar".get_children() + $"Inventory".get_children()

var last_pressed_slot_id


func _ready():
	for n in range(all_slots.size()):
		all_slots[n].pressed.connect(func():
			_on_slot_pressed(str(n))
		)
	


func _process(_delta):
	if player.client_inventory == null: return
	for n in range(player.client_inventory.values().size()):
		var slot = player.client_inventory.values()[n]
		if n < 8:
			$"Hotbar".get_child(n).display_slot(slot)
		else:
			$"Inventory".get_child(n - 8).display_slot(slot)
	


func _on_slot_pressed(slot_id):
	if last_pressed_slot_id == null: last_pressed_slot_id = slot_id; return
	match [player.client_inventory[last_pressed_slot_id].item_id != null, player.client_inventory[slot_id].item_id != null]:
		[true, false]:
			player.do_action_slot.rpc_id(1, last_pressed_slot_id, slot_id)
			
	last_pressed_slot_id = null
	


func _on_open_inventory_toggled(toggled_on):
	if toggled_on:
		$"Inventory".visible = true
	else:
		$"Inventory".visible = false
