extends CharacterBody2D


@export var main_node: Node2D
@export var healthpoints_max: int = 20
@export var healthpoints: int = 20

var already_dead: bool = false


func _process(_delta):
	if float(healthpoints) / healthpoints_max > 0.5:
		%Health.text = "[center]Squareenemy [color=green]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	elif float(healthpoints) / healthpoints_max > 0.2:
		%Health.text = "[center]Squareenemy [color=orange]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	else:
		%Health.text = "[center]Squareenemy [color=red]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]

func take_damage(damagepoints, rewards_user_record_id = ""):
	assert(multiplayer.is_server())
	healthpoints = clampi(healthpoints - damagepoints, 0, healthpoints_max)
	if healthpoints <= 0 and not already_dead:
		already_dead = true
		
		if rewards_user_record_id:
			await main_node.server.get_player_node(rewards_user_record_id).award_coins(3)
		await get_tree().create_timer(1).timeout
		main_node.entity_spawner.spawn({
			"entity": "squareenemy",
			"set_main_node": true,
			"properties": {
				"position": Vector2(300, 500)
			},
		})
		queue_free()

