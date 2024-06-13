extends Node


var item_sizes

@export var square_fragment_sprite_frames: SpriteFrames
@export var triangle_fragment_sprite_frames: SpriteFrames
@export var widesquare_fragment_fragment_sprite_frames: SpriteFrames

@onready var item_sprite_frames = {
	"square_fragment": square_fragment_sprite_frames,
	"triangle_fragment": triangle_fragment_sprite_frames,
	"widesquare_fragment": widesquare_fragment_fragment_sprite_frames,
}
