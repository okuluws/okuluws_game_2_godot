extends AnimatedSprite2D


@onready var items_config = $"../../Items/Common".config
var id
var stack


func _ready():
	sprite_frames = items_config[id].sprite_frames
