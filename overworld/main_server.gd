extends Node


@onready var server = $"../"
@onready var savefile = server.world_dir.path_join("overworld.cfg")
@onready var items_handler = server.get_node("Items")
@onready var multiplayer_spawner = $"MultiplayerSpawner"


func _ready():
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	server.start_queued.connect(func():
		var f = ConfigFile.new()
		if f.load(savefile) != OK: push_error("couldn't load %s" % savefile); return
		if not f.get_value("", "spawned_items", false):
			for n in range(1024):
				items_handler.spawn_item(["square_fragment", "triangle_fragment", "widesquare_fragment"].pick_random(), 1, Vector2(randi_range(100, 600), randi_range(-100, 100)))
			f.set_value("", "spawned_items", true)
			f.save(savefile)
			server.log_default("spawned items")
		multiplayer_spawner.spawn_function = func(_data): multiplayer_spawner.spawn_function = Callable(); return preload("res://overworld/overworld_server.tscn").instantiate()
		multiplayer_spawner.spawn("overworld")
		var new_squareenemy = preload("res://overworld/squareenemy/squareenemy_server.tscn").instantiate()
		#new_squareenemy.healthpoints = 20.0
		#new_squareenemy.healthpoints_max = 20.0
		multiplayer_spawner.spawn_function = func(_data): multiplayer_spawner.spawn_function = Callable(); return new_squareenemy
		multiplayer_spawner.spawn("squareenemy")
		
		server.log_default("spawned overworld")
	)

