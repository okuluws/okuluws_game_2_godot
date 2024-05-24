# NOTE:
# (23.05.2024) theres no polygon resource, using AnimationPlayer as a workaround, see https://github.com/godotengine/godot-proposals/issues/2960
#


extends Node


var peer_owner
var facing_direction
var coins
var healthpoints_max
var healthpoints
var inventory
var player_type
var display_text
var position

var _client_instance


func _ready():
	if multiplayer.is_server(): return
	_client_instance = load("res://players/player/client/client.tscn").instantiate()
	_client_instance.player_common = self
	add_sibling.call_deferred(_client_instance, true)


func _exit_tree():
	if _client_instance != null:
		_client_instance.queue_free()


signal rpc_i_am_not_idle
@rpc("any_peer", "reliable")
func i_am_not_idle():
	rpc_i_am_not_idle.emit()


signal rpc_set_player_velocity
@rpc("any_peer")
func set_player_velocity(velocity):
	rpc_set_player_velocity.emit(velocity)


signal rpc_set_player_facing_direction
@rpc("any_peer", "reliable")
func set_player_facing_direction(_facing_direction):
	rpc_set_player_facing_direction.emit(_facing_direction)


signal rpc_spawn_punch
@rpc("any_peer", "reliable")
func spawn_punch(_position, rotation, velocity):
	rpc_spawn_punch.emit(_position, rotation, velocity)


signal rpc_do_action_slot
@rpc("any_peer", "reliable")
func do_action_slot(slot_a, slot_b):
	rpc_do_action_slot.emit(slot_a, slot_b)


