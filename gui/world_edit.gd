extends CanvasLayer


@onready var main: Main = $"/root/Main"
const FuncU = preload("res://globals/FuncU.gd")
var world_folder_absolute: String


func _on_back_pressed():
	main.GUIs.add_child(main.world_selection_scene.instantiate())
	queue_free()
	


# TODO: Delete Confirmation
func _on_delete_world_pressed():
	for file in DirAccess.get_files_at(world_folder_absolute):
		DirAccess.remove_absolute("%s/%s" % [world_folder_absolute, file])
	DirAccess.remove_absolute(world_folder_absolute)
	main.GUIs.add_child(main.world_selection_scene.instantiate())
	queue_free()
	



func setup(_main: Main, _world_folder_absolute: String):
	world_folder_absolute = _world_folder_absolute
	var world_folder = DirAccess.open(world_folder_absolute)
	var world_config = FuncU.BetterConfigFile.new("%s/%s" % [world_folder.get_current_dir(), _main.world_script.CONFIG_FILENAME])
	$"Config Title".text = "%s - Config" % world_config.get_base_value("name")
