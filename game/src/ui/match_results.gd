## Match results screen — shown when match ends.
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var scores_container: VBoxContainer = $Panel/VBox/Scores
@onready var winner_label: Label = $Panel/VBox/WinnerLabel
@onready var play_again_button: Button = $Panel/VBox/Buttons/PlayAgain
@onready var menu_button: Button = $Panel/VBox/Buttons/MainMenu

var _shown: bool = false


func _ready() -> void:
	panel.visible = false
	play_again_button.pressed.connect(_on_play_again)
	menu_button.pressed.connect(_on_main_menu)
	EventBus.match_ended.connect(_on_match_ended)


func _on_match_ended(results: Dictionary) -> void:
	if _shown:
		return
	_shown = true
	panel.visible = true

	# Show winner
	var scoreboard: Array = results.get("scoreboard", [])
	if not scoreboard.is_empty():
		var winner: Dictionary = scoreboard[0]
		var winner_name: String = str(winner["name"])
		var is_local: bool = winner["id"] == GameState.local_player_id
		if is_local:
			winner_label.text = "YOU WIN!"
			winner_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			winner_label.text = "%s WINS!" % winner_name
			winner_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	# Populate scoreboard
	for child in scores_container.get_children():
		child.queue_free()

	for entry in scoreboard:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 30)

		var name_label := Label.new()
		name_label.text = str(entry["name"])
		name_label.custom_minimum_size = Vector2(120, 0)
		if entry["id"] == GameState.local_player_id:
			name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		row.add_child(name_label)

		var kills_label := Label.new()
		kills_label.text = "K: %s" % str(entry["kills"])
		kills_label.custom_minimum_size = Vector2(60, 0)
		row.add_child(kills_label)

		var deaths_label := Label.new()
		deaths_label.text = "D: %s" % str(entry["deaths"])
		deaths_label.custom_minimum_size = Vector2(60, 0)
		row.add_child(deaths_label)

		scores_container.add_child(row)


func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://src/maps/map_arena.tscn")


func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
