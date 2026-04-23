## Settings screen — volume, resolution, fullscreen.
extends Control

@onready var master_slider: HSlider = $Panel/VBox/MasterVolume/Slider
@onready var sfx_slider: HSlider = $Panel/VBox/SFXVolume/Slider
@onready var music_slider: HSlider = $Panel/VBox/MusicVolume/Slider
@onready var resolution_option: OptionButton = $Panel/VBox/Resolution/Option
@onready var fullscreen_check: CheckBox = $Panel/VBox/Fullscreen/Check
@onready var match_length_option: OptionButton = $Panel/VBox/MatchLength/Option
@onready var back_button: Button = $Panel/VBox/BackButton

var _match_lengths: Array[float] = [60.0, 120.0, 180.0, 300.0, 600.0]

var _resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]


func _ready() -> void:
	# Setup resolution options
	for res in _resolutions:
		resolution_option.add_item("%dx%d" % [res.x, res.y])

	# Find current resolution
	var current_size: Vector2i = DisplayServer.window_get_size()
	for i in _resolutions.size():
		if _resolutions[i] == current_size:
			resolution_option.selected = i
			break

	# Setup fullscreen
	var mode: int = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Setup match length
	match_length_option.add_item("1 min", 0)
	match_length_option.add_item("2 min", 1)
	match_length_option.add_item("3 min", 2)
	match_length_option.add_item("5 min", 3)
	match_length_option.add_item("10 min", 4)
	# Find current setting
	for i in _match_lengths.size():
		if absf(_match_lengths[i] - Constants.DEFAULT_TIME_LIMIT) < 1.0:
			match_length_option.selected = i
			break
	if match_length_option.selected < 0:
		match_length_option.selected = 3  # default 5 min

	# Setup volume sliders
	_setup_audio_buses()
	master_slider.value = _get_bus_volume("Master")
	sfx_slider.value = _get_bus_volume("SFX")
	music_slider.value = _get_bus_volume("Music")

	# Connect signals
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	resolution_option.item_selected.connect(_on_resolution_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	match_length_option.item_selected.connect(_on_match_length_changed)
	back_button.pressed.connect(_on_back)


func _setup_audio_buses() -> void:
	# Ensure SFX and Music buses exist
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "Master")
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.get_bus_index("Music"), "Master")


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


func _on_master_changed(value: float) -> void:
	_set_bus_volume("Master", value)


func _on_sfx_changed(value: float) -> void:
	_set_bus_volume("SFX", value)


func _on_music_changed(value: float) -> void:
	_set_bus_volume("Music", value)


func _on_match_length_changed(index: int) -> void:
	if index >= 0 and index < _match_lengths.size():
		Constants.DEFAULT_TIME_LIMIT = _match_lengths[index]


func _on_resolution_changed(index: int) -> void:
	if index >= 0 and index < _resolutions.size():
		var res: Vector2i = _resolutions[index]
		DisplayServer.window_set_size(res)
		# Center window
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var pos: Vector2i = (screen_size - res) / 2
		DisplayServer.window_set_position(pos)


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


var _previous_scene: String = "res://src/ui/main_menu.tscn"

func set_return_scene(scene_path: String) -> void:
	_previous_scene = scene_path

func _on_back() -> void:
	get_tree().change_scene_to_file(_previous_scene)
