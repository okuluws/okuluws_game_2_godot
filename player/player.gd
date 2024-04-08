extends CharacterBody2D


@export var facing_direction: Vector2 = Vector2.DOWN
@export var healthpoints_max: int = 10
@export var healthpoints: int = 10
@export var coins: int = 0
@export var player_type: String
@export var display_text: String

@export var main_node: Node2D
@export var peer_id: int
@export var user_record_id: String

@export var synced_position: Vector2
@export var is_idle: bool
@export var inventory: Array


func load_profile_data():
	assert(multiplayer.is_server())
	
	var profile_data = await main_node.server.get_profile_data(main_node.server.players[user_record_id]["profile_record_id"])
	coins = profile_data["coins"]
	healthpoints_max = profile_data["hp"]
	player_type = profile_data["player_type"]
	inventory = profile_data["inventory"]
	


func _ready():
	if multiplayer.is_server():
		set_process(false)
		set_physics_process(false)
		await load_profile_data()
		$IdleTimer.start()
		set_process(true)
		set_physics_process(true)


func _process(_delta):
	if multiplayer.is_server():
		display_text = "[center][color=white]%s " % main_node.server.players[user_record_id]["user_username"]
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
	if multiplayer.is_server():
		move_and_slide()
		synced_position = position
		
		if $IdleTimer.time_left == 0:
			is_idle = true
	
	else:
		if main_node.client.user_record_id == user_record_id:
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
			
			set_player_velocity.rpc_id(1, move_direction * 400)
			velocity = move_direction * 400
			move_and_slide()
			
			
			if Input.is_action_just_pressed("attack"):
				main_node.server.spawn_entity.rpc_id(1, {
					"entity_name": "punch",
					"set_main_node": true,
					"properties": {
						"auto_despawn": true,
						"user_record_id": user_record_id,
						"position": position + get_local_mouse_position().normalized()  * 80,
						"rotation": get_local_mouse_position().angle() + PI / 2,
						"velocity": get_local_mouse_position().normalized() * 1000,
					},
				})
			
			if ["move_left", "move_right", "move_up", "move_down", "attack"].any(func(_action): return Input.is_action_pressed(_action)):
				i_am_not_idle.rpc_id(1)
			
			
		else:
			position = main_node.client.predict_client_position(position, synced_position, 7, 40)
		
		
	


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

func award_coins(amount):
	await main_node.server.update_profile_entry(main_node.server.players[user_record_id]["profile_record_id"], "coins", func(value): return value + amount)
	load_profile_data()

func pickup_item(_item):
	#print("%s picked up item: %s" % [main_node.server.players[user_record_id]["user_username"], item.item_type])
	pass


