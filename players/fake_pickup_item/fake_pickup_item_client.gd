extends AnimatedSprite2D


@onready var items_config = $"../../Items/Common".config
var item_id


func _ready():
	sprite_frames = items_config[item_id].sprite_frames
