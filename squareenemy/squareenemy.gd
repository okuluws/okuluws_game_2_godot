extends CharacterBody2D


@onready var World: Node = get_viewport().get_child(0)
@onready var EntitySpawner: MultiplayerSpawner = World.EntitySpawner

var healthpoints_max: int = 20
var healthpoints: int = 20
var already_dead: bool = false
var entity_id: String


func _process(_delta):
	if float(healthpoints) / healthpoints_max > 0.5:
		%Health.text = "[center]Squareenemy [color=green]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	elif float(healthpoints) / healthpoints_max > 0.2:
		%Health.text = "[center]Squareenemy [color=orange]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	else:
		%Health.text = "[center]Squareenemy [color=red]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]

func take_damage(damagepoints, rewards_peer_):
	assert(multiplayer.is_server())
	healthpoints = clampi(healthpoints - damagepoints, 0, healthpoints_max)
	if healthpoints <= 0 and not already_dead:
		already_dead = true
		remove_from_group("Persist")
		
		for rewards_peer in rewards_peer_:
			# TODO: award coins
			pass
		await get_tree().create_timer(1).timeout
		EntitySpawner.spawn({
			"id": "squareenemy",
			"properties": {
				"position": Vector2(300, 500)
			},
		})
		queue_free()
	

func get_persistent():
	return {
		"data": {
			"position": position,
			"healthpoints_max": healthpoints_max,
			"healthpoints": healthpoints,
		},
		"handler": get_script().get_path()
	}

func load_persistent(data, _World):
	var squareenemy = _World.EntitySpawner.spawn({
		"id": "squareenemy",
		"properties": { "position": data.position }
	})
	
	squareenemy.healthpoints_max = data.healthpoints_max
	squareenemy.healthpoints = data.healthpoints
	# Why not set these in spawn()? - Both is possible but you should only do that if really needed like for position which would be set to zero before sync and that could mess things up client side



