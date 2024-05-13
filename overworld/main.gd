extends Node


func _ready():
	if get_parent().name == "Server":
		$"../".connect("finished_loading", func():$"../Level".add_child(preload("res://overworld/overworld.tscn").instantiate()))

