extends Node


# REQUIRED
@export var server: SubViewport

@onready var level = server.level
@onready var savefile = server.world_dir_path.path_join("items.cfg")
@export var item_spawner: MultiplayerSpawner
@export var config: Node
@export var item_scene: PackedScene
var items = []


func _ready():
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	server.load_queued.connect(_load_items)
	server.save_queued.connect(_save_items)
	
	item_spawner.spawn_path = level.get_path()


func spawn_item(item_id, stack, position):
	var new_item = item_scene.instantiate()
	new_item.id = item_id
	new_item.stack = stack
	new_item.position = position
	item_spawner.spawn_function = func(_data): item_spawner.spawn_function = Callable(); return new_item
	items.append(item_spawner.spawn())


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
	if not items.is_empty():
		push_error("items is not empty")
		return
	var f = ConfigFile.new()
	if f.load(savefile) != OK:
		push_error("couldn't load %s" % savefile)
		return
	for section in f.get_sections():
		spawn_item(f.get_value(section, "id"), f.get_value(section, "stack"), f.get_value(section, "position"))
	server.log_default("spawned items")
