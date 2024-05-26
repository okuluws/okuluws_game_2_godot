extends CanvasLayer


@onready var pocketbase = $"../Pocketbase"
var config = ConfigFile.new()
var latest_load_config_hash


func _ready():
	pocketbase.ready.connect(func(): add_child(load("res://home/title_screen.tscn").instantiate()))
	

