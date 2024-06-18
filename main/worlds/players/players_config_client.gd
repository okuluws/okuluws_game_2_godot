extends Node


@export var square_polygon: ConvexPolygonShape2D
@export var square_sprite_frames: SpriteFrames
@export var triangle_polygon: ConvexPolygonShape2D
@export var triangle_sprite_frames: SpriteFrames
@export var widesquare_polygon: ConvexPolygonShape2D
@export var widesquare_sprite_frames: SpriteFrames

@onready var player_type_polygons = {
	"square": square_polygon,
	"triangle": triangle_polygon,
	"widesquare": widesquare_polygon,
}

@onready var player_type_sprite_frames = {
	"square": square_sprite_frames,
	"triangle": triangle_sprite_frames,
	"widesquare": widesquare_sprite_frames,
}
