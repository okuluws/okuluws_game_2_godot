extends CanvasLayer


@onready var main: Main = $"/root/Main"
@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"


func _on_back_pressed() -> void:
	GUIs.add_child(main.home_scene.instantiate())
	queue_free()


func _on_join_server_pressed() -> void:
	var World: Main.world_class = main.world_scene.instantiate()
	main.add_child(World)
	World.start_client(($"Server Address" as RichTextLabel).text)
	queue_free()
	


func _on_host_locally_pressed() -> void:
	var World: Main.world_class = main.world_scene.instantiate()
	World.world_folder = Main.world_class.create_world_folder(main, "New World")
	main.add_child(World)
	World.start_server("New World", ($"Server Address" as RichTextLabel).text)
	queue_free()
	

