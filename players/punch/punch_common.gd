extends Node


var position
var rotation

var _client_instance


func _ready():
	if multiplayer.is_server(): return
	_client_instance = load("res://players/punch/punch_client.tscn").instantiate()
	_client_instance.punch_common = self
	add_sibling.call_deferred(_client_instance, true)


func _exit_tree():
	if _client_instance != null:
		_client_instance.queue_free()


