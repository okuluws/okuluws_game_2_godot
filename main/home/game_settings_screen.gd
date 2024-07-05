extends CanvasLayer


var home

@export var current_user_label: Label
@export var login_username_edit: LineEdit
@export var login_password_edit: LineEdit
@export var register_username_edit: LineEdit
@export var register_password_edit: LineEdit
@onready var main = home.main
@onready var pocketbase = main.modules.pocketbase


func _ready():
	pass
	


func _on_back_pressed():
	home.show_title_screen()
	queue_free()


func _on_logout_button_pressed():
	pass


func _on_login_button_pressed():
	pass # Replace with function body.


func _on_register_button_pressed():
	pass # Replace with function body.
