class_name Main extends Node


@export_dir var startup_scripts_folder
@export var GUIs: CanvasLayer


func _ready() -> void:
	print("loading startup scripts...")
	for script in DirAccess.get_files_at(startup_scripts_folder):
		print("%s/%s" % [startup_scripts_folder, script])
		load("%s/%s" % [startup_scripts_folder, script]).new(self)
	print("loaded startup scripts")
	

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
	
