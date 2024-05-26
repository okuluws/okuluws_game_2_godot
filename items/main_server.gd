extends Node


@onready var server = $"../"
@onready var savefile = server.world_dir.path_join("items.cfg")
@onready var level_handler = server.get_node("Level")
@onready var item_spawner = $"MultiplayerSpawner"
var items = []


func _ready():
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	server.load_queued.connect(_load_items)
	server.save_queued.connect(_save_items)


func spawn_item(item_id, stack, position):
	item_spawner.spawn_function = func(_data):
		var new_item = preload("res://items/item_server.tscn").instantiate()
		new_item.id = item_id
		new_item.stack = stack
		new_item.position = position
		return new_item
	items.append(item_spawner.spawn())
	item_spawner.spawn_function = func(): pass


func despawn_item(item: Node):
	item.queue_free()
	items.erase(item)


func _save_items():
	var f = ConfigFile.new()
	for i in items:
		f.set_value(i.name, "id", i.id)
		f.set_value(i.name, "stack", i.stack)
		f.set_value(i.name, "position", i.position)
	if f.save(savefile) != OK: push_error("couldn't save %s" % savefile); return
	server.log_default("saved items")


func _load_items():
	if not items.is_empty(): push_error("items is not empty"); return
	var f = ConfigFile.new()
	if f.load(savefile) != OK: push_error("couldn't load %s" % savefile); return
	for section in f.get_sections():
		spawn_item(f.get_value(section, "id"), f.get_value(section, "stack"), f.get_value(section, "position"))
	server.log_default("loaded items")

