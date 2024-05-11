# LOL

class_name Main extends Node

 
@export var GUIs: CanvasLayer


@export_dir var startup_scripts_folder: String
#const world_scene = preload("res://world/World.tscn")
#const world_class = preload("res://world/World.gd")
#const world_edit_class = preload("res://main/world_edit.gd")
#const world_display_class = preload("res://main/world_display.gd")
#@export var home_scene: PackedScene
#@export var server_selection_scene: PackedScene
#@export var world_selection_scene: PackedScene
#@export var world_edit_scene: PackedScene
#@export var world_display_scene: PackedScene
#
#@export var worlds_folder_name: String = "worlds"
#var worlds_folder: String:
	#get:
		#return "user://%s" % worlds_folder_name
	#set(_val):
		#printerr("property is readonly")
#
#const WORLD_CONFIG_FILENAME = "config.cfg"
#
#
## definitly not stolen code
#func parse_os_arguments() -> Dictionary:
	#var arguments := {}
	#for argument in OS.get_cmdline_args():
		#if argument.find("=") > -1:
			#var key_value := argument.split("=")
			#arguments[key_value[0].lstrip("--")] = key_value[1]
	#return arguments

func _ready() -> void:
	#print(OS.get_cmdline_args())
	#
	#if not DirAccess.dir_exists_absolute(worlds_folder):
		#DirAccess.make_dir_absolute(worlds_folder)
	#
	#var args := parse_os_arguments()
	#if args.has("server") and args.has("world"):
		#var world: world_class = world_scene.instantiate()
		#add_child(world)
		#if not DirAccess.dir_exists_absolute("%s/%s" % [worlds_folder, args.world]):
			#world_class.create_world_folder(self, args.get("world") as String)
		#world.start_server(args.get("world") as String, args.get("server") as String)
		#return
	
	print("loading startup scripts...")
	for script in DirAccess.get_files_at(startup_scripts_folder):
		print("%s/%s" % [startup_scripts_folder, script])
		
		# TODO: remove @warning_ignore by figuring out what type load() returns
		@warning_ignore("unsafe_method_access")
		load("%s/%s" % [startup_scripts_folder, script]).new(self)
	print("loaded startup scripts")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
