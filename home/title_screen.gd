extends Control


# REQUIRED
var home

@onready var pb = home.main.pb
@export var welcome_back_label: Label
@export var account_management_panel: Control
@export var auth_state_info: Label
@export var username_line_edit: LineEdit
@export var password_line_edit: LineEdit
@export var logout_button: BaseButton
@export var auth_response_label: Label


func _ready():
	pb.auth_changed.connect(_on_pocketbase_auth_changed)
	_on_pocketbase_auth_changed()


func _on_pocketbase_auth_changed():
	if pb.has_auth():
		welcome_back_label.text = "Welcome back %s!!" % pb.username
		auth_state_info.text = "Logged in as %s" % pb.username 
		logout_button.visible = true
	else:
		welcome_back_label.text = "Hello there new guy ;)"
		auth_state_info.text = "Not logged in"
		logout_button.visible = false


func _on_singleplayer_button_pressed():
	var new_world_selection = home.world_selection_scene.instantiate()
	new_world_selection.home = home
	home.add_child(new_world_selection)
	queue_free()


func _on_multiplayer_button_pressed():
	var new_server_selection = home.server_selection_scene.instantiate()
	new_server_selection.home = home
	home.add_child(new_server_selection)
	queue_free()


func _on_options_button_pressed():
	var new_game_options = home.game_options_scene.instantiate()
	new_game_options.home = home
	home.add_child(new_game_options)
	queue_free()


func _on_account_button_pressed():
	if account_management_panel.visible:
		_on_close_button_pressed()
	else:
		account_management_panel.visible = true


func _on_login_button_pressed():
	if await pb.auth_with_password(username_line_edit.text, password_line_edit.text) != OK:
		auth_response_label.text = "something went wrong"
	else:
		_on_close_button_pressed()


func _on_sign_up_button_pressed():
	if await pb.create_auth_record(username_line_edit.text, password_line_edit.text) != OK:
		auth_response_label.text = "something went wrong"
	else:
		_on_login_button_pressed()


func _on_close_button_pressed():
	account_management_panel.visible = false
	auth_response_label.text = ""
	username_line_edit.text = ""
	password_line_edit.text = ""


func _on_logout_button_pressed():
	pb.delete_auth()
	_on_close_button_pressed()


func _on_quit_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
