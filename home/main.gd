extends CanvasLayer


@onready var pocketbase = $"../Pocketbase"


func _ready():
	pocketbase.ready.connect(func(): add_child(load("res://home/title_screen.tscn").instantiate()))
	


