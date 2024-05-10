extends Node2D


@export var PersistHandler: Node

@onready var World: Main.world_class = get_viewport().get_child(0)
@onready var EntitySpawner: MultiplayerSpawner = World.EntitySpawner

var entity_id: String


func _ready() -> void:
	if multiplayer.is_server():
		pass
		#
		#EntitySpawner.spawn({
			#"entity_name": "square_fragment",
			#"properties": {
				#"position": Vector2(500, 500),
			#},
		#})
		#
		#EntitySpawner.spawn({
			#"entity_name": "widesquare_fragment",
			#"properties": {
				#"position": Vector2(700, 500),
			#},
		#})
		#
		#EntitySpawner.spawn({
			#"entity_name": "triangle_fragment",
			#"properties": {
				#"position": Vector2(900, 500),
			#},
		#})



	

