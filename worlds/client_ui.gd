extends CanvasLayer


var chat_message_scene = load("res://worlds/chat_message.tscn")
@onready var client = $"../"
@onready var tabs = $"Tabs"
@onready var chat_input_line = $"Tabs/Chat/LineEdit"
@onready var chat_container = $"Tabs/Chat/ScrollContainer/VBoxContainer"
@onready var chat_handler = client.get_node("Chat")


func _ready():
	chat_handler.received_message.connect(func():
		for n in chat_container.get_children(): n.queue_free()
		for s in chat_handler.public_chat:
			var new_chat_message = chat_message_scene.instantiate()
			new_chat_message.text = s
			chat_container.add_child(new_chat_message)
	)
	


func _on_resume_pressed():
	tabs.visible = false


func _on_quit_world_pressed():
	client.quit_world()


func _on_open_lan_pressed():
	pass # Replace with function body.


func _on_open_tabs_pressed():
	tabs.visible = not tabs.visible


func _on_send_message_pressed():
	print(chat_input_line.text)
	chat_handler.send_message.rpc_id(1, chat_input_line.text)

