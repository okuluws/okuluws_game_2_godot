extends Node


const GameMain = preload("res://main.gd")
@export var overworld_scene: PackedScene
@export var squareenemy_scene: PackedScene
@export var multiplayer_spawner: MultiplayerSpawner
var server: GameMain.Worlds.Server
var savefile: String


func init(p_server: GameMain.Worlds.Server):
	server = p_server
	savefile = server.world_dir_path.path_join("overworld.cfg")
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	
	var f = ConfigFile.new()
	if f.load(savefile) != OK: push_error("couldn't load %s" % savefile); return
	if not f.get_value("", "spawned_items", false):
		for n in range(256):
			server.modules.items.spawn_item(["square_fragment", "triangle_fragment", "widesquare_fragment"].pick_random(), randi_range(1, 4), Vector2(randi_range(100, 600), randi_range(-100, 100)))
		f.set_value("", "spawned_items", true)
		f.save(savefile)
		print("spawned overworld items")
	multiplayer_spawner.spawn_function = func(_data): multiplayer_spawner.spawn_function = Callable(); return overworld_scene.instantiate()
	multiplayer_spawner.spawn("overworld")
	var new_squareenemy = squareenemy_scene.instantiate()
	new_squareenemy.healthpoints = 20.0
	new_squareenemy.healthpoints_max = 20.0
	new_squareenemy.position = Vector2(-200 ,0)
	multiplayer_spawner.spawn_function = func(_data): multiplayer_spawner.spawn_function = Callable(); return new_squareenemy
	multiplayer_spawner.spawn("squareenemy")
	
	print("spawned overworld")
	
