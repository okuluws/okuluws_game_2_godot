class_name Main extends Node


const FunU = preload("res://globals/FuncU.gd")


func _ready():
	#print(IP.get_local_interfaces())
	#var k = Crypto.new().generate_rsa(256)
	#print(k.save_to_string())
	#print(k.save_to_string(true))
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
		print("closed game")
