extends Control


func _process(_delta):
	position = get_global_mouse_position() - size / 2

func update_textures(inventory: Dictionary):
	$"TextureRect".texture = Items.data[inventory["0"].item.type].texture if "0" in inventory else null
	$"RichTextLabel".text = "%d" % inventory["0"].stack if "0" in inventory and inventory["0"].stack > 1 else ""
