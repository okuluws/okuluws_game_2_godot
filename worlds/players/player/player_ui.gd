# NOTE: (24.05.2024) builtin multitouch should be implemented in the future, https://github.com/godotengine/godot-proposals/issues/3976

extends CanvasLayer


const GameMain = preload("res://main.gd")
@export var inventory_ui: GridContainer
@export var hotbar_ui: HBoxContainer
@export var movement_joypad_ring: Control
@export var movement_joypad_cirlce: Control
@export var punch_spawn_area: BaseButton
@export var movement_joypad_spawn_area: BaseButton
var player: GameMain.Worlds.Client.Players.Player
var main: GameMain
var action_slot_id
var moving_joypad = false


func init(p_player: GameMain.Worlds.Client.Players.Player):
	player = p_player
	for n in range(40):
		var new_item_slot = player.players.item_slot_scene.instantiate()
		new_item_slot.player = player
		new_item_slot.pressed.connect(func(): _on_slot_pressed(str(n)))
		if n < 8:
			hotbar_ui.add_child(new_item_slot)
		else:
			inventory_ui.add_child(new_item_slot)
	
	#if not main.get_virtual_joystick():
	if false:
		movement_joypad_spawn_area.disabled = true
		movement_joypad_spawn_area.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta):
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


# see notes
func _on_punch_spawn_area_gui_input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_spawn_punch(event.position)
	
