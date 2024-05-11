extends CanvasLayer

@export_file("*.gd") var world_script
@export_file("*.tscn") var world_file
@export_file("*.tscn") var title_screen_file
@onready var server_address: LineEdit = $"Server Address"


func _on_back_pressed() -> void:
	get_parent().add_child(load(title_screen_file).instantiate())
	queue_free()
	

func _on_join_server_pressed() -> void:
	var world = load(world_file).instantiate()
	$"../../".add_child(world)
	world.start_client(server_address.text)
	queue_free()
	

func _on_host_locally_pressed() -> void:
	var world = load(world_file).instantiate()
	load(world_script).create_world_folder("New World")
	$"../../".add_child(world)
	world.start_server("New World", server_address.text)
	queue_free()
	

