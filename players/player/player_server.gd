extends CharacterBody2D


@onready var server = $"../../"
@onready var level_handler = server.get_node("Level")
@onready var inventories_handler = server.get_node("Inventories")
@onready var items_handler = server.get_node("Items")

@onready var collision_animation_player = $"CollisionAnimationPlayer"
@onready var idle_timer = $"IdleTimer"

var player_common
var user_id
var username
var inventory_id
var is_idle = false


func _ready():
	player_common.facing_direction = Vector2.DOWN
	player_common.coins = 0
	player_common.healthpoints_max = 10
	player_common.healthpoints = 10
	player_common.display_text = ""
	player_common.position = position
	player_common.rpc_i_am_not_idle.connect(i_am_not_idle)
	player_common.rpc_set_player_velocity.connect(set_player_velocity)
	player_common.rpc_set_player_facing_direction.connect(set_player_facing_direction)
	player_common.rpc_spawn_punch.connect(spawn_punch)
	player_common.rpc_do_action_slot.connect(do_action_slot)


func _process(_delta):
	player_common.display_text = "[center][color=green]%s" % username
	if is_idle:
		player_common.display_text += "[color=darkgray][AFK][/color]"
	player_common.inventory = inventories_handler.inventories[inventory_id]
	
	match player_common.player_type:
		"square":
			collision_animation_player.play("player_type_collisions/square")
		"widesquare":
			collision_animation_player.play("player_type_collisions/widesquare")
		"triangle":
			collision_animation_player.play("player_type_collisions/triangle")


func _physics_process(_delta):
	if idle_timer.time_left == 0:
		is_idle = true
	move_and_slide()
	player_common.position = position
	velocity = velocity.lerp(Vector2.ZERO, 0.4)


func _exit_tree():
	player_common.queue_free()


func i_am_not_idle():
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	is_idle = false
	idle_timer.start()


func set_player_velocity(_velocity):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	velocity = _velocity


func set_player_facing_direction(_facing_direction):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	player_common.facing_direction = _facing_direction


func spawn_punch(_position, _rotation, _velocity):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	var new_punch_common = load("res://players/punch/punch_common.tscn").instantiate()
	var new_punch_server = load("res://players/punch/punch_server.tscn").instantiate()
	new_punch_server.punch_common = new_punch_common
	new_punch_server.peer_owner = player_common.peer_owner
	new_punch_server.position = _position
	new_punch_server.rotation = _rotation
	new_punch_server.velocity = _velocity
	add_sibling(new_punch_common, true)
	add_sibling(new_punch_server, true)


func _on_item_pickup_area_area_entered(item):
	if not items_handler.items.has(item): return
	if inventories_handler.push_item_to_inventory(item, inventory_id) > 0:
		var fake_pickup_item = load("res://players/player/common/fake_pickup_item.tscn").instantiate()
		fake_pickup_item.position = item.position
		fake_pickup_item.target_position = position
		fake_pickup_item.item_id = item.id
		level_handler.add_child(fake_pickup_item, true)


func do_action_slot(slot_a, slot_b):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	inventories_handler.push_slot_to_slot(inventory_id, slot_a, inventory_id, slot_b)


func _WARN_PEER_WRONG_PLAYER(remote_sender_id):
	if remote_sender_id != player_common.peer_owner: push_warning("peer %d tried to perform action on different player peer %d" % [remote_sender_id, player_common.peer_owner]); return true
	return false
