extends CharacterBody2D


const GameMain = preload("res://main.gd")
@export var player_ui_scene: PackedScene
@export var animated_sprite: AnimatedSprite2D
@export var camera: Camera2D
@export var display_label_top: RichTextLabel
@export var display_label_bottom: RichTextLabel
@export var collision_shape: CollisionShape2D
var players: GameMain.Worlds.Client.Players
var peer_owner
var facing_direction
var coins
var healthpoints_max
var healthpoints
var inventory
var player_type
var display_text


func init(p_players: GameMain.Worlds.Client.Players) -> void:
	if peer_owner != multiplayer.get_unique_id(): return
	camera.enabled = true
	var new_player_ui = players.player_ui_scene.instantiate()
	new_player_ui.player = self
	add_child(new_player_ui)


func _process(_delta):
	animated_sprite.sprite_frames = players.config.player_type_sprite_frames[player_type]
	match facing_direction:
		Vector2.LEFT:
			animated_sprite.play("left")
		Vector2.RIGHT:
			animated_sprite.play("right")
		_:
			animated_sprite.play("default")
	
	display_label_top.text = display_text
	display_label_bottom.text = "[center]  %d[color=red]♥ " % healthpoints
	
	collision_shape.shape = players.config.player_type_polygons[player_type]


func _physics_process(_delta):
	if peer_owner != multiplayer.get_unique_id(): return
	
	var move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
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
		set_player_velocity.rpc_id(1, move_direction * 300)
		i_am_not_idle.rpc_id(1)
	


@rpc func i_am_not_idle(): pass
@rpc func set_player_velocity(_velocity): pass
@rpc func set_player_facing_direction(_facing_direction): pass
@rpc func spawn_punch(_position, _rotation, _velocity): pass
@rpc func do_action_slot(): pass
