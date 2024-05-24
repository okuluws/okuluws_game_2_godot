extends Area2D


@onready var items_handler = $"../../Items"
var id
var stack


func despawn():
	items_handler.despawn_item(self)
