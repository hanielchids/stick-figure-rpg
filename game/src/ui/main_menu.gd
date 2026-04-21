## Main menu — Play, Settings, Quit.
extends Control


@onready var play_button: Button = $VBox/PlayButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var bot_count_spinner: SpinBox = $VBox/BotConfig/BotCount
@onready var difficulty_option: OptionButton = $VBox/BotConfig/Difficulty


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(null)  # Reset to default OS cursor
	play_button.pressed.connect(_on_play)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)

	difficulty_option.add_item("Easy", 0)
	difficulty_option.add_item("Medium", 1)
	difficulty_option.add_item("Hard", 2)
	difficulty_option.selected = 1


func _on_play() -> void:
	get_tree().change_scene_to_file("res://src/maps/map_arena.tscn")


func _on_settings() -> void:
	pass  # TODO: settings screen


func _on_quit() -> void:
	get_tree().quit()
