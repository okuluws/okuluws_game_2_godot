extends Node


const GameMain = preload("res://main.gd")
const source_directory = GameMain.Worlds.source_directory + "items/"
const Config = preload(source_directory + "items_config_server.gd")
@export var config: Config
@export var item_spawner: MultiplayerSpawner
@export var item_scene: PackedScene
var server: GameMain.Worlds.Server
var save_file: String
var items = []


func init(p_server: GameMain.Worlds.Server):
	server = p_server
	save_file = server.world_dirpath.path_join("items.cfg")
	server.saving.connect(_save_items)
	_load_items()


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
	if f.save(save_file) != OK: push_error("couldn't save %s" % save_file); return
	print("saved items")


func _load_items():
	if not items.is_empty():
		push_error("items is not empty")
		return
	var f = ConfigFile.new()
	if f.load(save_file) != OK:
		push_error("couldn't load %s" % save_file)
		return
	for section in f.get_sections():
		spawn_item(f.get_value(section, "id"), f.get_value(section, "stack"), f.get_value(section, "position"))
	print("spawned items")
