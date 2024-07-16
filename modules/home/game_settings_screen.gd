extends CanvasLayer


const Home = preload("main.gd")
const Pocketbase = preload("res://modules/pocketbase/pocketbase.gd")
@export var current_user_label: Label
@export var login_username_edit: LineEdit
@export var login_password_edit: LineEdit
@export var login_request_status_label: RichTextLabel
@export var register_username_edit: LineEdit
@export var register_password_edit: LineEdit
@export var register_request_status_label: RichTextLabel
var home: Home
var pocketbase: Pocketbase


func init(p_home: Home):
	home = p_home
	pocketbase = home.game_main.modules.pocketbase


func _ready():
	_update_auth_info_label()


func _update_auth_info_label():
	if pocketbase.has_current_auth():
		current_user_label.text = "Current user: %s" % pocketbase.get_current_username()
	else:
		current_user_label.text = "Not logged in."
	


func _on_back_pressed():
	home.show_title_screen()
	queue_free()


func _on_logout_button_pressed():
	if not pocketbase.has_current_auth(): return
	pocketbase.unset_current_auth()
	_update_auth_info_label()


func _on_login_button_pressed():
	pocketbase.auth_with_password("users", login_username_edit.text, login_password_edit.text, func(res):
		if res.err != null:
			push_error("couldn't login")
			login_request_status_label.text = "[color=red]something went wrong"
		else:
			login_request_status_label.text = "[color=green]success"
			_update_auth_info_label()
	)


func _on_register_button_pressed():
	pocketbase.create_record("users", { "username": register_username_edit.text, "password": register_password_edit.text, "passwordConfirm": register_password_edit.text }, func(res):
		if res.err != null:
			push_error("couldn't register")
			register_request_status_label.text = "[color=red]something went wrong"
		else:
			register_request_status_label.text = "[color=green]success"
	)
