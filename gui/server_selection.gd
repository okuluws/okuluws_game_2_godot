extends CanvasLayer


@onready var main: Main = $"/root/Main"
@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"


func _on_back_pressed():
	GUIs.add_child(main.home_scene.instantiate())
	queue_free()


func _on_join_server_pressed():
	var World = main.world_scene.instantiate()
	main.add_child(World)
	World.start_client($"Server Address".text)
	queue_free()
	


func _on_host_locally_pressed():
	var World = main.world_scene.instantiate()
	World.WORLD_FOLDER = World.create_world_folder("New World")
	main.add_child(World)
	World.start_server($"Server Address".text)
	queue_free()
	

