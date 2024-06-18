extends Control


# REQUIRED
var home
var world_dir_path

@export var title_label: Label
var world_config = ConfigFile.new()


func _ready():
	if world_config.load(world_dir_path.path_join("config.cfg")) != OK:
		push_error("[%s] couldn't load world config" % Time.get_time_string_from_system())
		_on_back_button_pressed()
		return
	title_label.text = "%s - Config" % world_config.get_value("", "name")


# TODO: Delete Confirmation
func _on_delete_world_button_pressed():
	for filename in DirAccess.get_files_at(world_dir_path):
		DirAccess.remove_absolute(world_dir_path.path_join(filename))
	DirAccess.remove_absolute(world_dir_path)
	var new_world_selection = home.world_selection_scene.instantiate()
	new_world_selection.home = home
	home.add_child(new_world_selection)
	queue_free()


func _on_back_button_pressed():
	var new_world_selection = home.world_selection_scene.instantiate()
	new_world_selection.home = home
	home.add_child(new_world_selection)
	queue_free()



