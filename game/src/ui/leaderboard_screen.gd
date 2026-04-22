## Leaderboard screen — shows top players from the backend.
extends Control

@onready var scores_container: VBoxContainer = $Panel/VBox/Scores
@onready var scope_option: OptionButton = $Panel/VBox/Header/ScopeOption
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var prev_button: Button = $Panel/VBox/PageButtons/PrevButton
@onready var next_button: Button = $Panel/VBox/PageButtons/NextButton
@onready var page_label: Label = $Panel/VBox/PageButtons/PageLabel

var _current_page: int = 1
var _current_scope: String = "kills"


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	scope_option.add_item("Kills", 0)
	scope_option.add_item("Wins", 1)
	scope_option.add_item("XP", 2)
	scope_option.add_item("Matches", 3)
	scope_option.selected = 0
	scope_option.item_selected.connect(_on_scope_changed)
	back_button.pressed.connect(_on_back)
	prev_button.pressed.connect(_on_prev_page)
	next_button.pressed.connect(_on_next_page)

	_fetch_leaderboard()


func _on_scope_changed(index: int) -> void:
	var scopes: Array[String] = ["kills", "wins", "total_xp", "matches_played"]
	_current_scope = scopes[index]
	_current_page = 1
	_fetch_leaderboard()


func _on_prev_page() -> void:
	if _current_page > 1:
		_current_page -= 1
		_fetch_leaderboard()


func _on_next_page() -> void:
	_current_page += 1
	_fetch_leaderboard()


func _fetch_leaderboard() -> void:
	if not ApiClient.is_logged_in:
		status_label.text = "Login required to view leaderboard"
		return

	status_label.text = "Loading..."
	page_label.text = "Page %d" % _current_page
	ApiClient.get_leaderboard(_current_scope, _current_page, _on_leaderboard_response)


func _on_leaderboard_response(response: Dictionary) -> void:
	# Clear old entries
	for child in scores_container.get_children():
		child.queue_free()

	if not response.get("ok", false):
		status_label.text = "Failed to load leaderboard"
		return

	var rankings: Array = response.get("rankings", [])
	if rankings.is_empty():
		status_label.text = "No players found"
		return

	status_label.text = ""

	for entry in rankings:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)

		var rank_label := Label.new()
		rank_label.text = "#%s" % str(entry.get("rank", "?"))
		rank_label.custom_minimum_size = Vector2(50, 0)
		row.add_child(rank_label)

		var name_label := Label.new()
		name_label.text = str(entry.get("username", "???"))
		name_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_label)

		var kills_label := Label.new()
		kills_label.text = "K:%s" % str(entry.get("kills", 0))
		kills_label.custom_minimum_size = Vector2(60, 0)
		row.add_child(kills_label)

		var wins_label := Label.new()
		wins_label.text = "W:%s" % str(entry.get("wins", 0))
		wins_label.custom_minimum_size = Vector2(60, 0)
		row.add_child(wins_label)

		var xp_label := Label.new()
		xp_label.text = "XP:%s" % str(entry.get("total_xp", 0))
		xp_label.custom_minimum_size = Vector2(80, 0)
		row.add_child(xp_label)

		scores_container.add_child(row)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
