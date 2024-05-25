extends CanvasLayer


@export var config_title: Label
@onready var home = $"../"
var world_dir


func _on_back_pressed() -> void:
	home.add_child(load("res://home/world_selection.tscn").instantiate())
	queue_free()
	

# TODO: Delete Confirmation
func _on_delete_world_pressed() -> void:
	for filename in DirAccess.get_files_at(world_dir):
		DirAccess.remove_absolute(world_dir.path_join(filename))
	DirAccess.remove_absolute(world_dir)
	home.add_child(load("res://home/world_selection.tscn").instantiate())
	queue_free()


func _ready() -> void:
	var world_config = ConfigFile.new()
	if world_config.load(world_dir.path_join("config.cfg")) != OK: push_error(); return
	config_title.text = "%s - Config" % world_config.get_value("", "name")
	

