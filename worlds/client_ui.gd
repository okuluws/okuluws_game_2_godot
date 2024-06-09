extends Control


# REQUIRED
@export var client: SubViewport

@export var world_texture_rect: TextureRect
@export var escape_panel: Panel


func _ready():
	world_texture_rect.texture = client.get_texture()


func _on_resume_button_pressed():
	escape_panel.visible = false


func _on_open_lan_button_pressed():
	pass # Replace with function body.


func _on_quit_world_button_pressed():
	client.quit_world()


func _on_open_escape_panel_button_pressed():
	escape_panel.visible = not escape_panel.visible








