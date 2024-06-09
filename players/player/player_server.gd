extends CharacterBody2D


# REQUIRED
var server

@onready var inventories = server.inventories
@onready var items = server.items
@onready var players = server.players
@onready var multiplayer_spawner = players.multiplayer_spawner
@export var collision_animation_player: AnimationPlayer
@export var idle_timer: Timer
var user_id
var username
var inventory_id
var is_idle = false
var peer_owner
var facing_direction = Vector2.DOWN
var coins = 0
var healthpoints_max = 10
var healthpoints = 10
var inventory
var player_type
var display_text = ""


func _process(_delta):
	display_text = "[center][color=green]%s" % username
	if is_idle:
		display_text += "[color=darkgray][AFK][/color]"
	inventory = inventories.inventories[inventory_id]
	
	match player_type:
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
	velocity = velocity.lerp(Vector2.ZERO, 0.4)


func _on_item_pickup_area_area_entered(item):
	if not items.items.has(item): return
	if inventories.push_item_to_inventory(item, inventory_id) > 0:
		var new_fake_pickup_item = players.fake_pickup_item_scene.instantiate()
		new_fake_pickup_item.position = item.position
		new_fake_pickup_item.target_position = position
		new_fake_pickup_item.item_id = item.id
		multiplayer_spawner.spawn_function = func(_data): multiplayer_spawner.spawn_function = Callable(); return new_fake_pickup_item
		multiplayer_spawner.spawn("fake_pickup_item")


@rpc("any_peer", "reliable")
func i_am_not_idle():
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	is_idle = false
	idle_timer.start()


@rpc("any_peer")
func set_player_velocity(_velocity):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	velocity = _velocity


@rpc("any_peer", "reliable")
func set_player_facing_direction(_facing_direction):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	facing_direction = _facing_direction


@rpc("any_peer", "reliable")
func spawn_punch(_position, _rotation, _velocity):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	var new_punch = players.punch_scene.instantiate()
	new_punch.peer_owner = peer_owner
	new_punch.position = _position
	new_punch.rotation = _rotation
	new_punch.velocity = _velocity
	multiplayer_spawner.spawn_function = func(_data): multiplayer_spawner.spawn_function = Callable(); return new_punch
	multiplayer_spawner.spawn("punch")
	


@rpc("any_peer", "reliable")
func do_action_slot(slot_a, slot_b):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	inventories.push_slot_to_slot(inventory_id, slot_a, inventory_id, slot_b)


func _WARN_PEER_WRONG_PLAYER(remote_sender_id):
	if remote_sender_id != peer_owner: push_warning("peer %d tried to perform action on different player peer %d" % [remote_sender_id, peer_owner]); return true
	return false


