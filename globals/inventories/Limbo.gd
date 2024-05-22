#extends Control
#
#
#func _process(_delta):
	#position = get_global_mouse_position() - size / 2
#
#func update_textures(slots: Dictionary):
	#$"TextureRect".texture = Items.config[slots["0"].item.type_id].texture if "0" in slots else null
	#$"RichTextLabel".text = "%d" % slots["0"].stack if "0" in slots and slots["0"].stack > 1 else ""
