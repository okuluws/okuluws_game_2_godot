extends CanvasLayer


@export_file("*.tscn") var title_screen_file


func _ready() -> void:
	add_child(load(title_screen_file).instantiate())
	
