extends CanvasLayer


@export var FuncU: Script
@export_file("*.tscn") var world_selection_file
@export var WORLD_CONFIG_FILENAME: String = "config.cfg"
@export var config_title: Label

var world_folder_absolute: String


func _on_back_pressed() -> void:
	get_parent().add_child(load(world_selection_file).instantiate())
	queue_free()
	

# TODO: Delete Confirmation
func _on_delete_world_pressed() -> void:
	for file in DirAccess.get_files_at(world_folder_absolute):
		DirAccess.remove_absolute("%s/%s" % [world_folder_absolute, file])
	DirAccess.remove_absolute(world_folder_absolute)
	get_parent().add_child(load(world_selection_file).instantiate())
	queue_free()
	

func setup(_world_folder_absolute: String) -> void:
	world_folder_absolute = _world_folder_absolute

func _ready() -> void:
	var world_folder := DirAccess.open(world_folder_absolute)
	var world_config = FuncU.BetterConfigFile.new("%s/%s" % [world_folder.get_current_dir(), WORLD_CONFIG_FILENAME])
	config_title.text = "%s - Config" % world_config.get_base_value("name")
	
