extends Node


const player_scene_filepath = "res://player/player.tscn"
@export var world: Node
var savefile = null

var players = {}


func _ready():
	if world.name == "Server":
		savefile = world.world_dir.path_join("players.cfg")
		if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		world.save_queued.connect(func():
			for p in players.values():
				_save_player(p)
		)
	
	if world.name == "Client":
		pass


func _PRINT_STAMP(s: String):
	print("[%s][%s] %s" % [name, Time.get_time_string_from_system(), s])


func _on_peer_connected(peer_id: int):
	var new_player = load(player_scene_filepath).instantiate()
	new_player.name = str(peer_id)
	new_player.username = world.peer_users[peer_id].username
	new_player.user_id = world.peer_users[peer_id].user_id
	new_player.peer_owner = peer_id
	_load_player_save(new_player)
	$"../Level".add_child(new_player)
	players[peer_id] = new_player
	_PRINT_STAMP("%s joined the game" % players[peer_id].username)

func _on_peer_disconnected(peer_id: int):
	_PRINT_STAMP("%s left the game" % players[peer_id].username)
	_save_player(players[peer_id])
	players[peer_id].queue_free()
	players.erase(peer_id)


func _save_player(player: Node):
	var cfg = ConfigFile.new()
	cfg.set_value(player.user_id, "position", player.position)
	cfg.set_value(player.user_id, "player_type", player.player_type)
	cfg.set_value(player.user_id, "inventory_id", player.inventory_id)
	if cfg.save(savefile) != OK: push_error("couldnt save file %s" % savefile); return FAILED
	_PRINT_STAMP("saved %s" % player.username)
	return OK


func _load_player_save(player: Node):
	var cfg = ConfigFile.new()
	if cfg.load(savefile) != OK: push_error("couldnt load file %s" % savefile); return FAILED
	player.position = cfg.get_value(player.user_id, "position", Vector2.ZERO)
	player.player_type = cfg.get_value(player.user_id, "player_type", ["square", "triangle", "widesquare"].pick_random())
	player.inventory_id = cfg.get_value(player.user_id, "inventory_id", $"../Inventories".create_default_inventory(32))
	_PRINT_STAMP("loaded save for %s" % player.username)
	return OK
