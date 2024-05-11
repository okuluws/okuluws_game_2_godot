extends CanvasLayer

@export var world_scene: PackedScene
@export var world_script: Script
@export var title_screen_scene: PackedScene
@onready var server_address: LineEdit = $"Server Address"


func _on_back_pressed() -> void:
	get_parent().add_child(title_screen_scene.instantiate())
	queue_free()
	

func _on_join_server_pressed() -> void:
	var world = world_scene.instantiate()
	$"../../".add_child(world)
	world.start_client(server_address.text)
	queue_free()
	

func _on_host_locally_pressed() -> void:
	var world = world_scene.instantiate()
	world_script.create_world_folder("New World")
	$"../../".add_child(world)
	world.start_server("New World", server_address.text)
	queue_free()
	

