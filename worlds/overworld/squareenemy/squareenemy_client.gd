extends AnimatedSprite2D


## synced from server
var healthpoints: float
## synced from server
var healthpoints_max: float


func _process(_delta):
	if healthpoints / healthpoints_max > 0.5:
		%HealthLabel.text = "[center]Squareenemy [color=green]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	elif healthpoints / healthpoints_max > 0.2:
		%HealthLabel.text = "[center]Squareenemy [color=orange]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
	else:
		%HealthLabel.text = "[center]Squareenemy [color=red]%d/%d[color=red]♥" % [healthpoints, healthpoints_max]
