extends CharacterBody2D


var punch_common


func _ready():
	position = punch_common.position
	rotation = punch_common.rotation


func _physics_process(_delta):
	position = punch_common.position
	rotation = punch_common.rotation
