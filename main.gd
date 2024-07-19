extends Node


const FuncU = preload("res://func_u/func_u.gd")
const Pocketbase = preload("res://pocketbase/pocketbase.gd")
const Worlds = preload("res://worlds/worlds.gd")
const Home = preload("res://home/main.gd")
@export var func_u: FuncU
@export var pocketbase: Pocketbase
@export var worlds: Worlds
@export var home: Home


func _ready():
	print("project version: %s" % ProjectSettings.get_setting_with_override("application/config/version"))
	pocketbase.init()
	worlds.init(self)
	home.init(self)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
