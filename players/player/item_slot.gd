extends TextureButton


# REQUIRED
@export var player_ui

@export var animated_sprite: AnimatedSprite2D
@export var overlay_texture_rect: TextureRect
@export var item_count_label: Label


func _process(_delta):
	animated_sprite.global_position = global_position + get_rect().size / 2


func _on_mouse_entered():
	overlay_texture_rect.visible = true


func _on_mouse_exited():
	overlay_texture_rect.visible = false


func display_slot(slot):
	if slot.item_id == null:
		animated_sprite.sprite_frames = null
		item_count_label.text = ""
		return
	
	animated_sprite.sprite_frames = $"../../../../../Items/Common".config[slot.item_id].sprite_frames
	item_count_label.text = ("%d" % slot.stack) if slot.stack > 1 else ""

