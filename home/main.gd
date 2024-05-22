extends CanvasLayer


var title_screen_file: String = "res://home/title_screen.tscn"
var server_selection_file: String = "res://home/server_selection.tscn"
var world_selection_file: String = "res://home/world_selection.tscn"
var world_edit_file: String = "res://home/world_edit.tscn"
var world_display_file: String = "res://home/world_display.tscn"

@onready var pocketbase = $"../Pocketbase"


func _ready():
	pocketbase.finished_ready.connect(func(): add_child(load(title_screen_file).instantiate()))
	


