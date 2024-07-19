extends Node


const GameMain = preload("res://main.gd")
@export var multiplayer_spawner: MultiplayerSpawner
@export var player_scene: PackedScene
@export var punch_scene : PackedScene
@export var fake_pickup_item_scene : PackedScene
@export var config: Node
var server: GameMain.Worlds.Server.Players
var savefile
var players = {}


func init(p_server: GameMain.Worlds.Server.Players) -> void:
	server = p_server
	savefile = server.world_dirpath.path_join("players.cfg")
	if not FileAccess.file_exists(savefile): FileAccess.open(savefile, FileAccess.WRITE)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	server.world_saving.connect(func():
		for p in players.values():
			_save_player(p)
	)


func _on_peer_connected(peer_id):
	var new_player = player_scene.instantiate()
	new_player.players = self
	new_player.peer_owner = peer_id
	new_player.username = server.peers[peer_id].username
	new_player.user_id = server.peers[peer_id].user_id
	_load_player_save(new_player)
	multiplayer_spawner.spawn_function = func(_data): multiplayer_spawner.spawn_function = Callable(); return new_player
	players[peer_id] = multiplayer_spawner.spawn("player")
	print("%s joined the game" % players[peer_id].username)



func _on_peer_disconnected(peer_id):
	print("%s left the game" % players[peer_id].username)
	_save_player(players[peer_id])
	players[peer_id].queue_free()
	players.erase(peer_id)


func _save_player(player):
	var cfg = ConfigFile.new()
	cfg.set_value(player.user_id, "position", player.position)
	cfg.set_value(player.user_id, "player_type", player.player_type)
	cfg.set_value(player.user_id, "inventory_id", player.inventory_id)
	if cfg.save(savefile) != OK: push_error("couldnt save file %s" % savefile); return FAILED
	print("saved player %s" % player.username)
	return OK


func _load_player_save(player):
	var cfg = ConfigFile.new()
	if cfg.load(savefile) != OK: push_error("couldnt load file %s" % savefile); return FAILED
	player.position = cfg.get_value(player.user_id, "position", Vector2.ZERO)
	player.player_type = cfg.get_value(player.user_id, "player_type", ["square", "triangle", "widesquare"].pick_random())
	player.inventory_id = cfg.get_value(player.user_id, "inventory_id") if cfg.has_section_key(player.user_id, "inventory_id") else server.modules.inventories.create_default_inventory(40)
	print("loaded player save for %s" % player.username)
	return OK
