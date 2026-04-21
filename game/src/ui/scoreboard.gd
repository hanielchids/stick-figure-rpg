## Scoreboard overlay — shown while Tab is held.
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var scores_container: VBoxContainer = $Panel/VBox


func _ready() -> void:
	panel.visible = false


func _process(_delta: float) -> void:
	if Input.is_action_pressed("scoreboard"):
		panel.visible = true
		_refresh_scores()
	else:
		panel.visible = false


func _refresh_scores() -> void:
	# Clear old entries (skip header)
	for i in range(scores_container.get_child_count() - 1, 0, -1):
		scores_container.get_child(i).queue_free()

	var scoreboard: Array = GameState.get_scoreboard()
	for entry in scoreboard:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 40)

		var name_label := Label.new()
		name_label.text = str(entry["name"])
		name_label.custom_minimum_size = Vector2(120, 0)
		var is_local: bool = entry["id"] == GameState.local_player_id
		if is_local:
			name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		row.add_child(name_label)

		var kills_label := Label.new()
		kills_label.text = str(entry["kills"])
		kills_label.custom_minimum_size = Vector2(50, 0)
		kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(kills_label)

		var deaths_label := Label.new()
		deaths_label.text = str(entry["deaths"])
		deaths_label.custom_minimum_size = Vector2(50, 0)
		deaths_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(deaths_label)

		scores_container.add_child(row)
