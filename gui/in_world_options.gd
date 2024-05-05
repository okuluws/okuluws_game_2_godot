extends CanvasLayer


@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"
@onready var World = $"/root/Main/World"
@onready var Main: Node = $"/root/Main"


func _on_leave_world_pressed():
	for node in World.get_children():
		World.remove_child(node)
	
	multiplayer.multiplayer_peer.close()
	for pid in Main.config.child_processes_pid:
		OS.kill(pid)
	
	GUIs.add_child(preload("res://gui/home.tscn").instantiate())
	queue_free()
	
