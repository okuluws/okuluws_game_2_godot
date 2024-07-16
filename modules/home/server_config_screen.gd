extends Control



const Home = preload("main.gd")
@export var node_world_name: LineEdit
@export var node_port: SpinBox
@export var node_bind_ip: LineEdit
var home: Home
var game_main: Home.GameMain
var world_dir_path: String
var c = ConfigFile.new()


func init(p_home: Home):
	home = p_home
	game_main = home.game_main


func _ready():
	var err = game_main.modules.func_u.ConfigFile_load(c, world_dir_path.path_join("world.cfg"))
	if err != null:
		push_error(err)
		queue_free()
		return
	
	node_world_name.text = c.get_value("general", "name")
	node_world_name.text_changed.connect(func(text):
		c.set_value("general", "name", text)
	)
	
	node_bind_ip.text = c.get_value("general", "bind_ip")
	node_bind_ip.text_changed.connect(func(text):
		c.set_value("general", "bind_ip", text)
	)
	
	node_port.value = c.get_value("general", "port")
	node_port.value_changed.connect(func(val):
		c.set_value("general", "port", val)
	)


func _on_btn_back_arrow_pressed():
	var err = game_main.modules.func_u.ConfigFile_save(c, world_dir_path.path_join("world.cfg"))
	if err != null: push_error(err)
	home.show_play_selection_screen()
	queue_free()
