# LOL

# PLANS:
# switch to C# for most stuff cause it has way better typing, maybe revert in future if gdscript has grown up
# i hope i wont regret this one ;)


extends Node


#@onready var GUIs = $"GUIs"


# definitly not stolen code
func parse_os_arguments():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	return arguments


func _ready():
	var args = parse_os_arguments()
	if args.has("server"):
		var World = preload("res://globals/World.tscn").instantiate()
		add_child(World)
		World.start_server(args.server)
		return
	
	$"GUIs".add_child(preload("res://gui/home.tscn").instantiate())
	

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
