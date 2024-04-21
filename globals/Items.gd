extends Node


var data = {
	"square_fragment": {
		"texture": preload("res://player/square/square_fragment.png"),
		"slot_size": 1,
	},
	"widesquare_fragment": {
		"texture": preload("res://player/widesquare/widesquare_fragment.png"),
		"slot_size": 1,
	},
	"triangle_fragment": {
		"texture": preload("res://player/triangle/triangle_fragment.png"),
		"slot_size": 1,
	},
}

func _ready():
	for item_name in data:
		assert(item_name not in Entities.data, "entity <%s> already exists" % item_name)
		
		var item = data[item_name]
		var item_template = preload("res://item/item.tscn").instantiate()
		item_template.get_node("Sprite2D").texture = item.texture
		item_template.data.name = item_name
		var item_scene = PackedScene.new()
		item_scene.pack(item_template)
		Entities.data[item_name] = item_scene
