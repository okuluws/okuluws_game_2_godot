extends Node


@export var world: Node
var savefile = null


func _ready():
	if world.name == "Server":
		savefile = world.world_dir.path_join("overworld.cfg")
		if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
		world.start_queued.connect(func():
			var f = ConfigFile.new()
			if f.load(savefile) != OK: push_error("couldn't load %s" % savefile); return
			if not f.get_value("", "spawned_items", false):
				$"../Items".spawn_item("square_fragment", 1, Vector2(200, 200))
				$"../Items".spawn_item("triangle_fragment", 1, Vector2(300, 200))
				$"../Items".spawn_item("widesquare_fragment", 1, Vector2(400, 200))
				f.set_value("", "spawned_items", true)
				f.save(savefile)
				_PRINT_STAMP("spawned items")
			$"../Level".add_child(load("res://overworld/overworld.tscn").instantiate())
		)


func _PRINT_STAMP(s: String):
	print("[%s][%s] %s" % [name, Time.get_time_string_from_system(), s])

