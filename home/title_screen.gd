extends CanvasLayer


@onready var home = $"../"
@onready var pocketbase = $"../../Pocketbase"


func _ready():
	pocketbase.auth_changed.connect(_on_pocketbase_auth_changed)
	_on_pocketbase_auth_changed()
	

func _on_pocketbase_auth_changed():
	if pocketbase.username != null:
		$"Welcome Back Message".text = "Welcome back %s!!" % pocketbase.username
		$"Account Manage Panel/Login Info".text = "Logged in as %s" % pocketbase.username 
		$"Account Manage Panel/Logout".visible = true
	else:
		$"Welcome Back Message".text = ""
		$"Account Manage Panel/Login Info".text = "Not logged in"
		$"Account Manage Panel/Logout".visible = false



func _on_multiplayer_pressed() -> void:
	home.add_child(load("res://home/server_selection.tscn").instantiate())
	queue_free()
	


func _on_singleplayer_pressed() -> void:
	home.add_child(load("res://home/world_selection.tscn").instantiate())
	queue_free()
	

func _on_quit_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	


func _on_account_pressed():
	if $"Account Manage Panel".visible:
		_on_close_pressed()
	else:
		$"Account Manage Panel".visible = true


func _on_login_pressed():
	if await pocketbase.auth_with_password($"Account Manage Panel/Username Line".text, $"Account Manage Panel/Password Line".text) != OK:
		$"Account Manage Panel/Request Response Info".text = "something went wrong"
	else:
		_on_close_pressed()

func _on_sign_up_pressed():
	if await pocketbase.create_auth_record($"Account Manage Panel/Username Line".text, $"Account Manage Panel/Password Line".text) != OK:
		$"Account Manage Panel/Request Response Info".text = "something went wrong"
	else:
		_on_login_pressed()


func _on_close_pressed():
	$"Account Manage Panel".visible = false
	$"Account Manage Panel/Request Response Info".text = ""
	$"Account Manage Panel/Username Line".text = ""
	$"Account Manage Panel/Password Line".text = ""


func _on_logout_pressed():
	pocketbase.delete_auth()
	_on_close_pressed()


func _on_options_pressed():
	home.add_child(load("res://home/game_options.tscn").instantiate())
	queue_free()
