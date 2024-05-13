class_name Main extends Node


const FunU = preload("res://globals/FuncU.gd")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
	
