extends ColorRect


@export var node: Control
var _is_mouse_inside = false


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	set_size(Vector2(size.x, 4))
	
	node.mouse_entered.connect(func():
		_is_mouse_inside = true
		visible = true
	)
	node.mouse_exited.connect(func():
		_is_mouse_inside = false
		if not node.has_focus():
			visible = false
	)
	node.focus_entered.connect(func():
		visible = true
	)
	node.focus_exited.connect(func():
		if not _is_mouse_inside:
			visible = false
	)

