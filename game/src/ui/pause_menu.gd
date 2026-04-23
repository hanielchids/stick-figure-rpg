## Pause menu — press Escape to toggle. Pauses the game tree.
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var quit_button: Button = $Panel/VBox/QuitButton

var _paused: bool = false


func _ready() -> void:
	panel.visible = false
	resume_button.pressed.connect(_on_resume)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep processing while paused


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	_paused = true
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _resume() -> void:
	_paused = false
	panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_resume() -> void:
	_resume()


func _on_settings() -> void:
	_resume()
	get_tree().change_scene_to_file("res://src/ui/settings_screen.tscn")


func _on_quit() -> void:
	_resume()
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
