extends Node


@onready var server = $"../"
@onready var level_handler = server.get_node("Level")
@onready var items_handler = server.get_node("Items")
@onready var savefile = null


func _ready():
	if not server.IS_SERVER: return
	
	savefile = server.world_dir.path_join("overworld.cfg")
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	server.start_queued.connect(func():
		var f = ConfigFile.new()
		if f.load(savefile) != OK: push_error("couldn't load %s" % savefile); return
		if not f.get_value("", "spawned_items", false):
			for n in range(4):
				items_handler.spawn_item(["square_fragment", "triangle_fragment", "widesquare_fragment"].pick_random(), randi_range(1, 3), Vector2(randi_range(100, 600), randi_range(-100, 100)))
			f.set_value("", "spawned_items", true)
			f.save(savefile)
			server.log_default("spawned items")
		level_handler.add_child(load("res://overworld/overworld.tscn").instantiate())
		server.log_default("spawned overworld")
	)

