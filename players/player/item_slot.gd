extends TextureButton


func _process(_delta):
	$"AnimatedSprite2D".global_position = global_position + get_rect().size / 2


func _on_mouse_entered():
	$"Overlay".visible = true


func _on_mouse_exited():
	$"Overlay".visible = false


func display_slot(slot):
	if slot.item_id == null:
		$"AnimatedSprite2D".sprite_frames = null
		$"Item Count".text = ""
		return
	
	$"AnimatedSprite2D".sprite_frames = $"../../../../../Items/Common".config[slot.item_id].sprite_frames
	$"Item Count".text = ("%d" % slot.stack) if slot.stack > 1 else ""

