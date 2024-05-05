extends CanvasLayer


@onready var Main: Node = $"/root/Main"
@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"


func _on_new_world_pressed():
	var World = preload("res://globals/World.tscn").instantiate()
	Main.add_child(World)
	World.start_local()
	queue_free()
	


func _on_back_pressed():
	GUIs.add_child(preload("res://gui/home.tscn").instantiate())
	queue_free()
	

func _ready():
	var worlds_folder = DirAccess.open("user://worlds")
	for dir_name in worlds_folder.get_directories():
		$"ScrollContainer/VBoxContainer"
