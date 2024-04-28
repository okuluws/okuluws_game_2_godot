extends Node


var data = {
	"square_fragment": {
		"display_name": "Square Fragment",
		"texture": preload("res://player/square/square_fragment.png"),
		"slot_size": 1,
	},
	"widesquare_fragment": {
		"display_name": "Widesquare Fragment",
		"texture": preload("res://player/widesquare/widesquare_fragment.png"),
		"slot_size": 1,
	},
	"triangle_fragment": {
		"display_name": "Triangle Fragment",
		"texture": preload("res://player/triangle/triangle_fragment.png"),
		"slot_size": 1,
	},
}

func _ready():
	for item_id in data:
		assert(item_id not in Entities.data, "entity <%s> already exists" % item_id)
		
		var item = data[item_id]
		var item_template = preload("res://item/item.tscn").instantiate()
		item_template.get_node("Sprite2D").texture = item.texture
		item_template.data.display_name = item.display_name
		item_template.data.type = item_id
		var item_scene = PackedScene.new()
		item_scene.pack(item_template)
		Entities.data[item_id] = item_scene
