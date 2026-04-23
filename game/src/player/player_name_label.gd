## Displays the player/bot name above the character.
extends Label

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent()

	# Style
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 10)
	add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)

	# Position above character head
	position = Vector2(-30, -50)
	size = Vector2(60, 15)

	# Set the name text
	_update_name()


func _update_name() -> void:
	if not player:
		return

	var player_id: int = player.player_id
	if GameState.players.has(player_id):
		text = str(GameState.players[player_id].get("name", ""))
	else:
		text = "Player %d" % player_id

	# Color: green for local player, white for others
	if player_id == GameState.local_player_id:
		add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 0.9))
	else:
		add_theme_color_override("font_color", Color(1, 1, 1, 0.7))


func _process(_delta: float) -> void:
	if player and player.is_dead:
		visible = false
	else:
		visible = true
