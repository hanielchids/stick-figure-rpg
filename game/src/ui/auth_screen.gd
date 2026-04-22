## Login / Signup screen. First screen players see.
## On success, stores token and proceeds to main menu.
extends Control

@onready var email_input: LineEdit = $Panel/VBox/EmailInput
@onready var username_input: LineEdit = $Panel/VBox/UsernameInput
@onready var password_input: LineEdit = $Panel/VBox/PasswordInput
@onready var login_button: Button = $Panel/VBox/Buttons/LoginButton
@onready var signup_button: Button = $Panel/VBox/Buttons/SignupButton
@onready var skip_button: Button = $Panel/VBox/SkipButton
@onready var status_label: Label = $Panel/VBox/StatusLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	login_button.pressed.connect(_on_login)
	signup_button.pressed.connect(_on_signup)
	skip_button.pressed.connect(_on_skip)
	status_label.text = ""
	username_input.visible = false  # Only shown for signup


func _on_login() -> void:
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text.strip_edges()

	if email.is_empty() or password.is_empty():
		status_label.text = "Enter email and password"
		return

	status_label.text = "Logging in..."
	login_button.disabled = true
	ApiClient.login(email, password, _on_login_response)


func _on_signup() -> void:
	# Toggle username field visibility
	if not username_input.visible:
		username_input.visible = true
		status_label.text = "Enter username, email, and password"
		return

	var username: String = username_input.text.strip_edges()
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text.strip_edges()

	if username.is_empty() or email.is_empty() or password.is_empty():
		status_label.text = "Fill in all fields"
		return

	status_label.text = "Creating account..."
	signup_button.disabled = true
	ApiClient.signup(username, email, password, _on_signup_response)


func _on_login_response(response: Dictionary) -> void:
	login_button.disabled = false
	if response.get("ok", false):
		ApiClient.set_auth_token(response.get("token", ""))
		ApiClient.current_user = response.get("user", {})
		_go_to_menu()
	else:
		var error: String = response.get("error", "Login failed")
		status_label.text = str(error)


func _on_signup_response(response: Dictionary) -> void:
	signup_button.disabled = false
	if response.get("ok", false):
		ApiClient.set_auth_token(response.get("token", ""))
		ApiClient.current_user = response.get("user", {})
		_go_to_menu()
	else:
		var errors = response.get("errors", response.get("error", "Signup failed"))
		if errors is Array:
			status_label.text = ", ".join(errors)
		else:
			status_label.text = str(errors)


func _on_skip() -> void:
	# Play without account
	_go_to_menu()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
