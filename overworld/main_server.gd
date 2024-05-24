extends Node


@onready var server = $"../"
@onready var savefile = server.world_dir.path_join("overworld.cfg")
@onready var items_handler = server.get_node("Items")
@onready var multiplayer_spawner = $"MultiplayerSpawner"


func _ready():
	multiplayer_spawner.spawn_function = func(_data): return preload("res://overworld/overworld_server.tscn").instantiate()
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
		multiplayer_spawner.spawn()
		server.log_default("spawned overworld")
	)

