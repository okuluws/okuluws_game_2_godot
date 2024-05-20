extends Node


@export var world: Node
var config = {
	"square_fragment": {
		"sprite_frames": load("res://items/square_fragment.tres"),
		"size": 1.0
	},
	"triangle_fragment": {
		"sprite_frames": load("res://items/triangle_fragment.tres"),
		"size": 1.0
	},
	"widesquare_fragment": {
		"sprite_frames": load("res://items/widesquare_fragment.tres"),
		"size": 1.0
	},
}
var items = []
var savefile = null


func _ready():
	if world.name == "Server":
		savefile = world.world_dir.path_join("items.cfg")
		if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
		world.load_queued.connect(_load_items)
		world.save_queued.connect(_save_items)


func spawn_item(item_id: String, stack: int, position: Vector2):
	var new_item = load("res://items/item.tscn").instantiate()
	new_item.id = item_id
	new_item.stack = stack
	new_item.position = position
	$"../Level".add_child(new_item, true)
	items.append(new_item)


func despawn_item(item: Node):
	item.queue_free()
	items.erase(item)


func _PRINT_STAMP(s: String):
	print("[%s][%s] %s" % [name, Time.get_time_string_from_system(), s])


func _save_items():
	var f = ConfigFile.new()
	for i in items:
		f.set_value(i.get_path(), "id", i.id)
		f.set_value(i.get_path(), "stack", i.stack)
		f.set_value(i.get_path(), "position", i.position)
	if f.save(savefile) != OK: push_error("couldn't save %s" % savefile); return
	_PRINT_STAMP("saved items")


func _load_items():
	if not items.is_empty(): push_error("items is not empty"); return
	var f = ConfigFile.new()
	if f.load(savefile) != OK: push_error("couldn't load %s" % savefile); return
	for section in f.get_sections():
		spawn_item(f.get_value(section, "id"), f.get_value(section, "stack"), f.get_value(section, "position"))
	_PRINT_STAMP("loaded items")

