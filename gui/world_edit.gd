extends CanvasLayer


@onready var GUIs: CanvasLayer = $"/root/Main/GUIs"
const FuncU = preload("res://globals/FuncU.gd")

var world_folder_absolute: String


func _on_back_pressed():
	GUIs.add_child(preload("res://gui/world_selection.tscn").instantiate())
	queue_free()
	


# TODO: Delete Confirmation
func _on_delete_world_pressed():
	for file in DirAccess.get_files_at(world_folder_absolute):
		DirAccess.remove_absolute("%s/%s" % [world_folder_absolute, file])
	DirAccess.remove_absolute(world_folder_absolute)
	GUIs.add_child(preload("res://gui/world_selection.tscn").instantiate())
	queue_free()
	



func setup(_world_folder_absolute: String):
	world_folder_absolute = _world_folder_absolute
	var world_folder = DirAccess.open(world_folder_absolute)
	var world_config = FuncU.BetterConfigFile.new("%s/config.cfg" % world_folder.get_current_dir())
	$"Config Title".text = "%s - Config" % world_config.get_base_value("name")
