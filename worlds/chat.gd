extends Node


signal received_message
var public_chat = []


@rpc("any_peer", "reliable")
func send_message(s):
	public_chat.append(s)


func _on_multiplayer_synchronizer_delta_synchronized():
	received_message.emit()
