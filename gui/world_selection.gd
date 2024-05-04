extends CanvasLayer


@onready var Main: Node = $"/root/Main"
@onready var Server: Node = Main.Server
@onready var Client: Node = Main.Client
@onready var GUIs: CanvasLayer = Main.GUIs


func _on_new_world_pressed():
	Server.start("127.0.0.1:42000")
	Client.start("127.0.0.1:42000")
	queue_free()


func _on_back_pressed():
	GUIs.add_child(preload("res://gui/home.tscn").instantiate())
	queue_free()
