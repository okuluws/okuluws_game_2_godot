extends GridContainer


signal itemslot_selected(index)

func _ready():
	for n in get_child_count():
		get_child(n).connect("pressed", emit_signal.bind("itemslot_selected", n))

