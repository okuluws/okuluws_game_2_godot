class_name Main extends Node


const FunU = preload("res://globals/FuncU.gd")


func _ready() -> void:
	var mods_cfg = FunU.BetterConfigFile.new("user://mods.cfg")
	mods_cfg.set_base_value("Home", "res://home/main.tscn")
	mods_cfg.set_base_value("Worlds", "res://worlds/main.tscn")
	mods_cfg.save()
	
	var mods_node = Node.new()
	mods_node.name = "Mods"
	
	print("loading mods ...")
	for mod_name in mods_cfg.get_base_section_keys():
		prints("loading", mod_name, "at", mods_cfg.get_base_value(mod_name))
		var node = load(mods_cfg.get_base_value(mod_name)).instantiate()
		node.name = mod_name
		mods_node.add_child(node)
	add_child(mods_node)
	print("loading mods done.")
	

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
	
