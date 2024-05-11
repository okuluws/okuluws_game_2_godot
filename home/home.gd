extends CanvasLayer


@export var title_screen_scene: PackedScene
#const server_selection_scene = preload("./server_selection.tscn")
#const world_selection_scene = preload("./world_selection.tscn")
#const world_edit_scene = preload("./world_edit.tscn")
#const WorldEdit = preload("./world_edit.gd")
#const world_display_scene = preload("./world_display.tscn")
#const WorldDisplay = preload("./world_display.gd")
#const world_scene = preload("res://world/World.tscn")
#const World = preload("res://world/World.gd")


func _init() -> void:
	add_child(title_screen_scene.instantiate())
	
