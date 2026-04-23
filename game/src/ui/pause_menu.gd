## Pause menu — press Escape to toggle. Pauses the game tree.
## Settings open as an overlay, not a scene change.
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var quit_button: Button = $Panel/VBox/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/VBox/MasterVolume/Slider
@onready var sfx_slider: HSlider = $SettingsPanel/VBox/SFXVolume/Slider
@onready var music_slider: HSlider = $SettingsPanel/VBox/MusicVolume/Slider
@onready var settings_back_button: Button = $SettingsPanel/VBox/BackButton

var _paused: bool = false


func _ready() -> void:
	panel.visible = false
	settings_panel.visible = false
	resume_button.pressed.connect(_on_resume)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	settings_back_button.pressed.connect(_on_settings_back)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Setup volume sliders
	master_slider.value = _get_bus_volume("Master")
	sfx_slider.value = _get_bus_volume("SFX")
	music_slider.value = _get_bus_volume("Music")
	master_slider.value_changed.connect(func(v: float) -> void: _set_bus_volume("Master", v))
	sfx_slider.value_changed.connect(func(v: float) -> void: _set_bus_volume("SFX", v))
	music_slider.value_changed.connect(func(v: float) -> void: _set_bus_volume("Music", v))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			_on_settings_back()
		elif _paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	_paused = true
	panel.visible = true
	settings_panel.visible = false
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _resume() -> void:
	_paused = false
	panel.visible = false
	settings_panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_resume() -> void:
	_resume()


func _on_settings() -> void:
	panel.visible = false
	settings_panel.visible = true


func _on_settings_back() -> void:
	settings_panel.visible = false
	panel.visible = true


func _on_quit() -> void:
	_resume()
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")


func _get_bus_volume(bus_name: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.001, 1.0)))
