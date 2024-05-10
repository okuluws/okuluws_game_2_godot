#extends CanvasLayer
#
#
#@export var player: Node2D
#
#
#func _process(_delta):
	#if player:
		#%Coins.text = str(player.coins)
		#%Scene.text = player.get_parent().name
		#
		#%Health.text = "%d / %d" % [player.healthpoints, player.healthpoints_max]
		#%HealthTexture.texture.region.position.x = 256 * ceilf(10 * float(player.healthpoints_max) / player.healthpoints)
	#
