# LOL


extends Node


@export var GUIs: CanvasLayer


# definitly not stolen code
func parse_os_arguments():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	return arguments


func _ready():
	print(OS.get_cmdline_args())
	
	if not DirAccess.dir_exists_absolute("user://worlds"):
		DirAccess.make_dir_absolute("user://worlds")
	
	var args = parse_os_arguments()
	if args.has("server") and args.has("world"):
		var World = preload("res://globals/World.tscn").instantiate()
		add_child(World)
		if not DirAccess.dir_exists_absolute(args.world):
			World.start_server(World.create_world_folder(Array(args.world.split("/")).back()), args.server)
		else:
			World.start_server(args.world, args.server)
		return
	
	$"GUIs".add_child(preload("res://gui/home.tscn").instantiate())
	

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
