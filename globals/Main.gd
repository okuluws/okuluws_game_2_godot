# LOL


class_name Main

extends Node


@export var GUIs: CanvasLayer

@export var world_scene: PackedScene
@export var world_script: Script
@export var home_scene: PackedScene
@export var server_selection_scene: PackedScene
@export var world_selection_scene: PackedScene
@export var world_edit_scene: PackedScene
@export var world_display_scene: PackedScene

@export var worlds_folder_name: String = "worlds"
var worlds_folder: String:
	get:
		return "user://%s" % worlds_folder_name
	set(_val):
		printerr("property is readonly")


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
	
	if not DirAccess.dir_exists_absolute(worlds_folder):
		DirAccess.make_dir_absolute(worlds_folder)
	
	var args = parse_os_arguments()
	if args.has("server") and args.has("world"):
		var world = world_scene.instantiate()
		add_child(world)
		if not DirAccess.dir_exists_absolute("%s/%s" % [worlds_folder, args.world]):
			world_script.create_world_folder(self, args.world)
		
		world.start_server(args.world, args.server)
		return
	
	$"GUIs".add_child(home_scene.instantiate())
	

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
