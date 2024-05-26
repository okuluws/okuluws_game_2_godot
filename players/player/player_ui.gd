# NOTE: (24.05.2024) builtin multitouch should be implemented in the future, https://github.com/godotengine/godot-proposals/issues/3976

extends CanvasLayer


@onready var main = $"/root/Main"
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
	
	# multitouch, see NOTES
	$"PunchSpawnArea".gui_input.connect(func(event):
		if event is InputEventScreenTouch:
			if event.pressed:
				_spawn_punch(event.position)
	)
	
	if not main.get_virtual_joystick():
		$"MovementJoypadSpawnArea".disabled = true
		$"MovementJoypadSpawnArea".mouse_filter = Control.MOUSE_FILTER_IGNORE


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
		if delta_position.length() > 70:
			movement_joypad_ring.global_position = movement_joypad_ring.global_position.move_toward(movement_joypad_cirlce.global_position, delta_position.length() - 70)
		
		# doppelt hält besser (clamp technically not needed)
		Input.action_press("move_left",  clamp(-delta_position.x / 70, 0, 1))
		Input.action_press("move_right", clamp( delta_position.x / 70, 0, 1))
		Input.action_press("move_up",    clamp(-delta_position.y / 70, 0, 1))
		Input.action_press("move_down",  clamp( delta_position.y / 70, 0, 1))


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


func _spawn_punch(mouse_position):
	#player.get_canvas_transform().affine_inverse() * mouse_position
	var normal = player.to_local(player.get_canvas_transform().affine_inverse() * mouse_position).normalized()
	player.spawn_punch.rpc_id(1, player.position + normal * 80, Vector2.ZERO.angle_to_point(normal) + PI / 2, normal * 1000)

