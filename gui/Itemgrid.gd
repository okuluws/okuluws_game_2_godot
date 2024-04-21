extends GridContainer


signal itemslot_selected(index)
signal itemslot_mouse_entered(index)
signal itemslot_mouse_exited(index)

func _ready():
	for n in get_child_count():
		get_child(n).connect("button_down", emit_signal.bind("itemslot_selected", n))
		get_child(n).connect("mouse_entered", emit_signal.bind("itemslot_mouse_entered", n))
		get_child(n).connect("mouse_exited", emit_signal.bind("itemslot_mouse_exited", n))

