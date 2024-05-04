extends CharacterBody2D


# TODO: better static typing
@onready var World: Node = $"/root/Main/World"
@onready var Client: Node = $"/root/Main/Client"

var facing_direction: Vector2 = Vector2.DOWN
var healthpoints_max: int = 10
var healthpoints: int = 10
var coins: int = 0
var player_type: String
var display_text: String
var is_idle: bool


func _ready():
	if World.RUNNING_SERVER:
		$IdleTimer.start()



func _process(_delta):
	if World.RUNNING_SERVER:
		display_text = "[center][color=green]Player %s" % name
		if is_idle:
			display_text += "[color=darkgray][AFK][/color]"
	
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
	



func _physics_process(_delta):
	if World.RUNNING_SERVER:
		if $IdleTimer.time_left == 0:
			is_idle = true
	
	if World.RUNNING_CLIENT:
		if name == str(Client.multiplayer.get_unique_id()):
			var move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			var move_direction_signed = move_direction.sign()
			
			if move_direction_signed.x == -1:
				Client.multiplayer.rpc(1, self, "set_player_facing_direction", [Vector2.LEFT])
			elif move_direction_signed.x == 1:
				Client.multiplayer.rpc(1, self, "set_player_facing_direction", [Vector2.RIGHT])
			elif move_direction_signed.y == -1:
				Client.multiplayer.rpc(1, self, "set_player_facing_direction", [Vector2.UP])
			elif move_direction_signed.y == 1:
				Client.multiplayer.rpc(1, self, "set_player_facing_direction", [Vector2.DOWN])
			
			Client.multiplayer.rpc(1, self, "set_player_velocity", [move_direction * 400])
			#set_player_velocity.rpc_id(1, move_direction * 400)
			velocity = move_direction * 400
			
			#if Input.is_action_just_pressed("attack"):
				#Server.spawn_entity.rpc_id(1, {
					#"entity_name": "punch",
					#"properties": {
						#"auto_despawn": true,
						#"user_record_id": user_record_id,
						#"position": position + get_local_mouse_position().normalized()  * 80,
						#"rotation": get_local_mouse_position().angle() + PI / 2,
						#"velocity": get_local_mouse_position().normalized() * 1000,
					#},
				#})
			#
			#if ["move_left", "move_right", "move_up", "move_down", "attack"].any(func(_action): return Input.is_action_pressed(_action)):
				#i_am_not_idle.rpc_id(1)
			#
			#if Input.is_action_just_pressed("open_inventory"):
				#Client.inventory_gui.visible = not Client.inventory_gui.visible
	
	move_and_slide()


@rpc("any_peer")
func i_am_not_idle():
	assert(multiplayer.is_server())
	is_idle = false
	$IdleTimer.start()

@rpc("any_peer")
func set_player_velocity(_velocity):
	assert(multiplayer.is_server())
	velocity = _velocity

@rpc("any_peer")
func set_player_facing_direction(_facing_direction):
	assert(multiplayer.is_server())
	facing_direction = _facing_direction

#@rpc("any_peer")

