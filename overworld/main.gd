extends Node


func _ready():
	if $"../".name == "Server":
		$"../".finished_loading.connect(func(): $"../Level".add_child(load("res://overworld/overworld.tscn").instantiate()))

