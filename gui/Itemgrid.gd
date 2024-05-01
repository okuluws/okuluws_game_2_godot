extends GridContainer


signal itemslot_left_click(index)
signal itemslot_right_click(index)
signal itemslot_mouse_entered(index)
signal itemslot_mouse_exited(index)
var left_click_sweep = []
signal itemslot_left_click_sweep(indexes)
var right_click_sweep = []
signal itemslot_right_click_sweep(indexes)

func _ready():
	for n in get_child_count():
		var slot_node = get_child(n)
		slot_node.connect("button_down", func():
			if Input.is_action_pressed("left_click"):
				left_click_sweep.append(n)
				itemslot_left_click.emit(n)
			elif Input.is_action_pressed("right_click"):
				right_click_sweep.append(n)
				itemslot_right_click.emit(n)
		)
		slot_node.connect("button_up", func():
			left_click_sweep = []
			right_click_sweep = []
		)
		slot_node.connect("mouse_entered", func():
			itemslot_mouse_entered.emit(n)
			if Input.is_action_pressed("left_click"):
				if not n in left_click_sweep:
					left_click_sweep.append(n)
				itemslot_left_click_sweep.emit(left_click_sweep)
			elif Input.is_action_pressed("right_click"):
				if not n in right_click_sweep:
					right_click_sweep.append(n)
				itemslot_right_click_sweep.emit(right_click_sweep)
		)
		slot_node.connect("mouse_exited", func(): itemslot_mouse_exited.emit(n))


func update_textures(slots: Dictionary, inventory_type_id):
	for n in range(Inventories.config[inventory_type_id].slot_count).map(func(val): return str(val)):
		var slot_node = get_child(n.to_int())
		slot_node.get_node("TextureRect").texture = Items.config[slots[n].item.type_id].texture if n in slots else null
		slot_node.get_node("RichTextLabel").text = "%d" % slots[n].stack if n in slots and slots[n].stack > 1 else ""
	
