extends CanvasLayer


const Home = preload("./home.gd")
@onready var home: Home = get_parent()
@onready var server_address: LineEdit = $"Server Address"


func _on_back_pressed() -> void:
	home.add_child(home.title_screen_scene.instantiate())
	queue_free()
	

func _on_join_server_pressed() -> void:
	var world: Home.World = home.world_scene.instantiate()
	home.main.add_child(world)
	world.start_client(server_address.text)
	queue_free()
	

func _on_host_locally_pressed() -> void:
	var world: Home.World = home.world_scene.instantiate()
	Home.World.create_world_folder("New World")
	home.main.add_child(world)
	world.start_server("New World", server_address.text)
	queue_free()
	

