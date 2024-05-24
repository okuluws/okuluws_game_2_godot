extends CharacterBody2D


@onready var server = $"../../"
@onready var inventories_handler = server.get_node("Inventories")
@onready var items_handler = server.get_node("Items")
@onready var multiplayer_spawner = server.get_node("Players").multiplayer_spawner
@onready var collision_animation_player = $"CollisionAnimationPlayer"
@onready var idle_timer = $"IdleTimer"

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
	inventory = inventories_handler.inventories[inventory_id]
	
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
	if not items_handler.items.has(item): return
	if inventories_handler.push_item_to_inventory(item, inventory_id) > 0:
		multiplayer_spawner.spawn_function = func(_data):
			var new_fake_pickup_item = preload("res://players/fake_pickup_item/fake_pickup_item_server.tscn").instantiate()
			new_fake_pickup_item.position = item.position
			new_fake_pickup_item.target_position = position
			new_fake_pickup_item.item_id = item.id
			return new_fake_pickup_item
		multiplayer_spawner.spawn("fake_pickup_item")
		multiplayer_spawner.spawn_function = func(): pass


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
	multiplayer_spawner.spawn_function = func(_data):
		var new_punch = preload("res://players/punch/punch_server.tscn").instantiate()
		new_punch.peer_owner = peer_owner
		new_punch.position = _position
		new_punch.rotation = _rotation
		new_punch.velocity = _velocity
		return new_punch
	multiplayer_spawner.spawn("punch")
	multiplayer_spawner.spawn_function = func(): pass
	


@rpc("any_peer", "reliable")
func do_action_slot(slot_a, slot_b):
	if _WARN_PEER_WRONG_PLAYER(multiplayer.get_remote_sender_id()): return
	inventories_handler.push_slot_to_slot(inventory_id, slot_a, inventory_id, slot_b)


func _WARN_PEER_WRONG_PLAYER(remote_sender_id):
	if remote_sender_id != peer_owner: push_warning("peer %d tried to perform action on different player peer %d" % [remote_sender_id, peer_owner]); return true
	return false


