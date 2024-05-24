extends CanvasLayer


@onready var player = $"../"
@onready var inventory_ui = $"Inventory"
@onready var hotbar_ui = $"Hotbar"
@onready var all_slots = hotbar_ui.get_children() + inventory_ui.get_children()
@onready var movement_joypad_ring = $"MovementJoypadRing"
@onready var movement_joypad_cirlce = $"MovementJoypadCircle"

var action_slot_id
var moving_joypad = false


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
	
	if moving_joypad:
		movement_joypad_cirlce.global_position = movement_joypad_cirlce.get_global_mouse_position()
		var delta_position: Vector2 = movement_joypad_cirlce.global_position - movement_joypad_ring.global_position
		if delta_position.length() > 80:
			movement_joypad_ring.global_position = movement_joypad_ring.global_position.move_toward(movement_joypad_cirlce.global_position, delta_position.length() - 80)
		
		# doppelt hält besser (clamp technically not needed)
		Input.action_press("move_left",  clamp(-delta_position.x / 80, 0, 1))
		Input.action_press("move_right", clamp( delta_position.x / 80, 0, 1))
		Input.action_press("move_up",    clamp(-delta_position.y / 80, 0, 1))
		Input.action_press("move_down",  clamp( delta_position.y / 80, 0, 1))


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


func _on_movement_joypad_spawn_area_button_down():
	moving_joypad = true
	movement_joypad_ring.visible = true
	movement_joypad_cirlce.visible = true
	movement_joypad_ring.global_position = movement_joypad_ring.get_global_mouse_position() - movement_joypad_ring.size / 2


func _on_movement_joypad_spawn_area_button_up():
	moving_joypad = false
	movement_joypad_ring.visible = false
	movement_joypad_cirlce.visible = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
