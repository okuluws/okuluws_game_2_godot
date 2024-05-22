extends CharacterBody2D


var peer_owner
var player_type
var username
var user_id
var inventory_id

var facing_direction: Vector2 = Vector2.DOWN
var healthpoints_max: int = 10
var healthpoints: int = 10
var coins: int = 0
var display_text: String
var is_idle: bool
var client_inventory


func _ready() -> void:
	if multiplayer.is_server():
		$IdleTimer.start()
	elif peer_owner == multiplayer.get_unique_id():
		$"Camera2D".enabled = true
		add_child(preload("res://player/ui.tscn").instantiate())
	

func _process(_delta: float) -> void:
	if multiplayer.is_server():
		display_text = "[center][color=green]%s" % username
		if is_idle:
			display_text += "[color=darkgray][AFK][/color]"
		client_inventory = $"../../Inventories".inventories[inventory_id]
	
	match player_type:
		"square":
			$CollisionAnimationPlayer.play("collision_square")
		"widesquare":
			$CollisionAnimationPlayer.play("collision_widesquare")
		"triangle":
			$CollisionAnimationPlayer.play("collision_triangle")
	
	
	match [player_type, facing_direction]:
		["square", Vector2.LEFT]:
			$AnimationPlayer.play("square_left")
		["square", Vector2.RIGHT]:
			$AnimationPlayer.play("square_right")
		["square", Vector2.UP], ["square", Vector2.DOWN]:
			$AnimationPlayer.play("square")
		
		["widesquare", Vector2.LEFT]:
			$AnimationPlayer.play("widesquare_left")
		["widesquare", Vector2.RIGHT]:
			$AnimationPlayer.play("widesquare_right")
		["widesquare", Vector2.UP], ["widesquare", Vector2.DOWN]:
			$AnimationPlayer.play("widesquare")
	
		["triangle", Vector2.LEFT]:
			$AnimationPlayer.play("triangle_left")
		["triangle", Vector2.RIGHT]:
			$AnimationPlayer.play("triangle_right")
		["triangle", Vector2.UP], ["triangle", Vector2.DOWN]:
			$AnimationPlayer.play("triangle")
	
	
	$RichTextLabel.text = display_text
	$RichTextLabel2.text = "[center]  %d[color=red]♥ " % healthpoints
	



func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		if $IdleTimer.time_left == 0:
			is_idle = true
	
	elif peer_owner == multiplayer.get_unique_id():
		var move_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var move_direction_signed := move_direction.sign()
		
		if move_direction_signed.x == -1:
			set_player_facing_direction.rpc_id(1, Vector2.LEFT)
		elif move_direction_signed.x == 1:
			set_player_facing_direction.rpc_id(1, Vector2.RIGHT)
		elif move_direction_signed.y == -1:
			set_player_facing_direction.rpc_id(1, Vector2.UP)
		elif move_direction_signed.y == 1:
			set_player_facing_direction.rpc_id(1, Vector2.DOWN)
		
		if move_direction != Vector2.ZERO or ["move_left", "move_right", "move_up", "move_down"].any(func(a): return Input.is_action_just_released(a)):
			set_player_velocity.rpc_id(1, move_direction * 400)
		#velocity = move_direction * 400
		
		if Input.is_action_just_pressed("attack"):
			spawn_punch.rpc_id(1, position + get_local_mouse_position().normalized() * 80, get_local_mouse_position().angle() + PI / 2, get_local_mouse_position().normalized() * 1000)
			
		
		if ["move_left", "move_right", "move_up", "move_down", "attack"].any(func(_action: String) -> bool: return Input.is_action_pressed(_action)):
			i_am_not_idle.rpc_id(1)
	
	
	move_and_slide()


@rpc("any_peer", "reliable")
func i_am_not_idle() -> void:
	if multiplayer.get_remote_sender_id() != peer_owner: push_warning("unauthorized player action from peer %d" ); return
	is_idle = false
	$IdleTimer.start()

@rpc("any_peer")
func set_player_velocity(_velocity: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != peer_owner: push_warning("unauthorized player action from peer %d" ); return
	velocity = _velocity

@rpc("any_peer", "reliable")
func set_player_facing_direction(_facing_direction: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != peer_owner: push_warning("unauthorized player action from peer %d" ); return
	facing_direction = _facing_direction

@rpc("any_peer", "reliable")
func spawn_punch(_position: Vector2, _rotation: float, _velocity: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != peer_owner: push_warning("unauthorized player action from peer %d" ); return
	var new_punch = load("res://player/punch.tscn").instantiate()
	new_punch.peer_owner = peer_owner
	new_punch.position = _position
	new_punch.rotation = _rotation
	new_punch.velocity = _velocity
	add_sibling(new_punch, true)
	


func _on_item_pickup_area_area_entered(item):
	if not multiplayer.is_server(): return
	if not $"../../Items".items.has(item): return
	if $"../../Inventories".push_item_to_inventory(item, inventory_id) > 0:
		var fake_pickup_item = preload("res://player/fake_pickup_item.tscn").instantiate()
		fake_pickup_item.position = item.position
		fake_pickup_item.target_position = position
		fake_pickup_item.item_id = item.id
		$"../".add_child(fake_pickup_item, true)


@rpc("any_peer", "reliable")
func do_action_slot(slot_a, slot_b):
	if multiplayer.get_remote_sender_id() != peer_owner: push_warning("unauthorized player action from peer %d" ); return
	$"../../Inventories".push_slot_to_slot(inventory_id, slot_a, inventory_id, slot_b)
	prints(slot_a, slot_b)
	
	
