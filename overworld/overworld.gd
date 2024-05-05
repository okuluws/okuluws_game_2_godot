extends Node2D


@onready var World: Node = $"/root/Main/World"
@onready var EntitySpawner: MultiplayerSpawner = World.EntitySpawner

var entity_id: String


func _ready():
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


func get_persistent():
	return {
		"data": {},
		"handler": get_script().get_path(),
	}

func load_persistent(_data, _World):
	_World.EntitySpawner.spawn({
		"id": "overworld"
	})
	

