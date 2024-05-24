extends Node


@onready var server = $"../"
@onready var savefile = server.world_dir.path_join("players.cfg")
@onready var level_handler = server.get_node("Level")
@onready var inventories_handler = server.get_node("Inventories")
@onready var player_spawner = $"MultiplayerSpawner"
var players = {}


func _ready():
	player_spawner.spawn_function = _spawn_function
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	server.save_queued.connect(func():
		for p in players.values():
			_save_player(p)
	)


func _spawn_function(_data):
	#var new_item = preload("res://players/main_client.tscn").instantiate()
	#return new_item
	pass


func _on_peer_connected(peer_id: int):
	var new_player_common = load("res://players/player/common/common.tscn").instantiate()
	new_player_common.name = str(peer_id)
	new_player_common.peer_owner = peer_id
	
	var new_player_server = load("res://players/player/server/server.tscn").instantiate()
	new_player_server.player_common = new_player_common
	new_player_server.username = server.peer_users[peer_id].username
	new_player_server.user_id = server.peer_users[peer_id].user_id
	_load_player_save(new_player_server)
	players[peer_id] = new_player_server
	
	level_handler.add_child(new_player_common, true)
	level_handler.add_child(new_player_server, true)
	server.log_default("%s joined the game" % players[peer_id].username)


func _on_peer_disconnected(peer_id: int):
	server.log_default("%s left the game" % players[peer_id].username)
	_save_player(players[peer_id])
	players[peer_id].queue_free()
	players.erase(peer_id)


func _save_player(player: Node):
	var cfg = ConfigFile.new()
	cfg.set_value(player.user_id, "position", player.position)
	cfg.set_value(player.user_id, "player_type", player.player_common.player_type)
	cfg.set_value(player.user_id, "inventory_id", player.inventory_id)
	if cfg.save(savefile) != OK: push_error("couldnt save file %s" % savefile); return FAILED
	server.log_default("saved player %s" % player.username)
	return OK


func _load_player_save(player: Node):
	var cfg = ConfigFile.new()
	if cfg.load(savefile) != OK: push_error("couldnt load file %s" % savefile); return FAILED
	player.position = cfg.get_value(player.user_id, "position", Vector2.ZERO)
	player.player_common.player_type = cfg.get_value(player.user_id, "player_type", ["square", "triangle", "widesquare"].pick_random())
	player.inventory_id = cfg.get_value(player.user_id, "inventory_id") if cfg.has_section_key(player.user_id, "inventory_id") else inventories_handler.create_default_inventory(40)
	server.log_default("loaded player save for %s" % player.username)
	return OK
