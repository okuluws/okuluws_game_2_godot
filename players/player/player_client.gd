extends CharacterBody2D


@onready var collision_animation_player = $"CollisionAnimationPlayer"
@onready var animated_sprite = $"AnimatedSprite2D"
var player_common


func _ready():
	position = player_common.position
	if player_common.peer_owner != multiplayer.get_unique_id(): return
	$"Camera2D".enabled = true
	add_child.call(load("res://players/player/client/ui.tscn").instantiate())


func _process(_delta):
	match player_common.player_type:
		"square":
			collision_animation_player.play("player_type_collisions/square")
		"widesquare":
			collision_animation_player.play("player_type_collisions/widesquare")
		"triangle":
			collision_animation_player.play("player_type_collisions/triangle")
	
	match [player_common.player_type, player_common.facing_direction]:
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
	
	$"DisplayLabelTop".text = player_common.display_text
	$"DisplayLabelBottom".text = "[center]  %d[color=red]♥ " % player_common.healthpoints


func _physics_process(_delta):
	position = player_common.position
	if player_common.peer_owner != multiplayer.get_unique_id(): return
	
	var move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction_signed = move_direction.sign()
	
	if move_direction_signed.x == -1:
		player_common.set_player_facing_direction.rpc_id(1, Vector2.LEFT)
	elif move_direction_signed.x == 1:
		player_common.set_player_facing_direction.rpc_id(1, Vector2.RIGHT)
	elif move_direction_signed.y == -1:
		player_common.set_player_facing_direction.rpc_id(1, Vector2.UP)
	elif move_direction_signed.y == 1:
		player_common.set_player_facing_direction.rpc_id(1, Vector2.DOWN)
	
	if move_direction != Vector2.ZERO:
		player_common.set_player_velocity.rpc_id(1, move_direction * 350)
	
	if Input.is_action_just_pressed("attack"):
		player_common.spawn_punch.rpc_id(1, position + get_local_mouse_position().normalized() * 80, get_local_mouse_position().angle() + PI / 2, get_local_mouse_position().normalized() * 1000)
	
	if ["move_left", "move_right", "move_up", "move_down", "attack"].any(func(_action: String) -> bool: return Input.is_action_pressed(_action)):
		player_common.i_am_not_idle.rpc_id(1)
	
	
	
