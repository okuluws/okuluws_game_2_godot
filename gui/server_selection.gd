extends CanvasLayer


@onready var Main: Node = $"/root/Main"
@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"


func _on_back_pressed():
	GUIs.add_child(preload("res://gui/home.tscn").instantiate())
	queue_free()


func _on_join_server_pressed():
	var World = preload("res://globals/World.tscn").instantiate()
	Main.add_child(World)
	World.start_client($"Server Address".text)
	queue_free()
	


func _on_host_locally_pressed():
	var World = preload("res://globals/World.tscn").instantiate()
	World.WORLD_FOLDER = preload("res://globals/World.gd").create_world_folder("New World")
	Main.add_child(World)
	World.start_server($"Server Address".text)
	queue_free()
	

