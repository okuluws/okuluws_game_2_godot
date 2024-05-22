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
				for n in range(1024):
					$"../Items".spawn_item(["square_fragment", "triangle_fragment", "widesquare_fragment"].pick_random(), randi_range(1, 3), Vector2(randi_range(100, 600), randi_range(-100, 100)))
				f.set_value("", "spawned_items", true)
				f.save(savefile)
				_PRINT_STAMP("spawned items")
			$"../Level".add_child(load("res://overworld/overworld.tscn").instantiate())
		)


func _PRINT_STAMP(s: String):
	print("[%s][%s] %s" % [name, Time.get_time_string_from_system(), s])

