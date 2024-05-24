extends CharacterBody2D


@onready var collision_animation_player = $"CollisionAnimationPlayer"
@onready var animated_sprite = $"AnimatedSprite2D"

var peer_owner
var facing_direction
var coins
var healthpoints_max
var healthpoints
var inventory
var player_type
var display_text


func _ready():
	if peer_owner != multiplayer.get_unique_id(): return
	$"Camera2D".enabled = true
	add_child.call(load("res://players/player/player_ui.tscn").instantiate())


func _process(_delta):
	match [player_type, facing_direction]:
		["square", Vector2.LEFT]:
			animated_sprite.play("square_left")
		["square", Vector2.RIGHT]:
			animated_sprite.play("square_right")
		["square", Vector2.UP], ["square", Vector2.DOWN]:
			animated_sprite.play("square")
		
		["widesquare", Vector2.LEFT]:
			animated_sprite.play("widesquare_left")
		["widesquare", Vector2.RIGHT]:
			animated_sprite.play("widesquare_right")
		["widesquare", Vector2.UP], ["widesquare", Vector2.DOWN]:
			animated_sprite.play("widesquare")
	
		["triangle", Vector2.LEFT]:
			animated_sprite.play("triangle_left")
		["triangle", Vector2.RIGHT]:
			animated_sprite.play("triangle_right")
		["triangle", Vector2.UP], ["triangle", Vector2.DOWN]:
			animated_sprite.play("triangle")
	
	$"DisplayLabelTop".text = display_text
	$"DisplayLabelBottom".text = "[center]  %d[color=red]♥ " % healthpoints


func _physics_process(_delta):
	if peer_owner != multiplayer.get_unique_id(): return
	
	var move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction_signed = move_direction.sign()
	
	if move_direction_signed.x == -1:
		set_player_facing_direction.rpc_id(1, Vector2.LEFT)
	elif move_direction_signed.x == 1:
		set_player_facing_direction.rpc_id(1, Vector2.RIGHT)
	elif move_direction_signed.y == -1:
		set_player_facing_direction.rpc_id(1, Vector2.UP)
	elif move_direction_signed.y == 1:
		set_player_facing_direction.rpc_id(1, Vector2.DOWN)
	
	if move_direction != Vector2.ZERO:
		set_player_velocity.rpc_id(1, move_direction * 350)
	
	if Input.is_action_just_pressed("attack"):
		spawn_punch.rpc_id(1, position + get_local_mouse_position().normalized() * 80, get_local_mouse_position().angle() + PI / 2, get_local_mouse_position().normalized() * 1000)
	
	if ["move_left", "move_right", "move_up", "move_down", "attack"].any(func(_action): return Input.is_action_pressed(_action)):
		i_am_not_idle.rpc_id(1)
	
	


@rpc func i_am_not_idle(): pass
@rpc func set_player_velocity(_velocity): pass
@rpc func set_player_facing_direction(_facing_direction): pass
@rpc func spawn_punch(_position, _rotation, _velocity): pass
@rpc func do_action_slot(): pass



