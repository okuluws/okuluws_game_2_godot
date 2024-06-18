extends Node


@export var square_polygon: ConvexPolygonShape2D
@export var triangle_polygon: ConvexPolygonShape2D
@export var widesquare_polygon: ConvexPolygonShape2D

@onready var player_type_polygons = {
	"square": square_polygon,
	"triangle": triangle_polygon,
	"widesquare": widesquare_polygon,
}
