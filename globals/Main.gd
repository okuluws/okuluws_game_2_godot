extends Node


#@onready var Client = $"Client"
#@onready var Server = $"Server"
#@onready var World = $"World"
#@onready var GUIs = $"GUIs"
#@onready var EntitySpawner = $"MultiplayerSpawner"


var config = {
	"entities": {
		"overworld": preload("res://overworld/overworld.tscn"),
		"player": preload("res://player/player.tscn"),
	}
}


func _ready():
	$"GUIs".add_child(preload("res://gui/home.tscn").instantiate())
