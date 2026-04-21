## Manages a match — spawns bots alongside the existing player, tracks score.
## The human player is already placed in the map scene.
## This script only spawns bots using bot.tscn (which has NO Camera2D).
extends Node

var bot_scene: PackedScene = preload("res://src/ai/bot.tscn")

@export var bot_count: int = 3
@export var score_limit: int = Constants.DEFAULT_SCORE_LIMIT
@export var time_limit: float = Constants.DEFAULT_TIME_LIMIT

var spawn_manager: SpawnPointManager
var match_active: bool = false
var match_timer: float = 0.0
var _bots: Array[CharacterBody2D] = []


func _ready() -> void:
	# Find spawn manager and player in the scene
	for child in get_parent().get_children():
		if child is SpawnPointManager:
			spawn_manager = child

	# Register the existing human player into the group and game state
	var human_player: Node = get_parent().get_node_or_null("Player")
	if human_player and human_player is CharacterBody2D:
		human_player.add_to_group("players")
		GameState.add_player(human_player.player_id, "Player")
		GameState.local_player_id = human_player.player_id

	# Wait one frame so the scene tree is fully ready before adding bots
	await get_tree().process_frame
	_start_match()


func _process(delta: float) -> void:
	if not match_active:
		return

	match_timer += delta
	if match_timer >= time_limit:
		_end_match()
		return

	var winner_id: int = GameState.check_win_condition()
	if winner_id >= 0:
		_end_match()


func _start_match() -> void:
	GameState.reset()
	GameState.current_state = GameState.MatchState.IN_PROGRESS
	GameState.max_score = score_limit
	GameState.match_time_limit = time_limit
	match_timer = 0.0
	match_active = true

	# Re-register human player after reset
	var human_player: Node = get_parent().get_node_or_null("Player")
	if human_player and human_player is CharacterBody2D:
		human_player.add_to_group("players")
		GameState.add_player(human_player.player_id, "Player")
		GameState.local_player_id = human_player.player_id

	# Spawn bots
	var bot_names: Array[String] = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Ghost"]
	for i in bot_count:
		var bot_name: String = bot_names[i % bot_names.size()]
		_spawn_bot(i + 1, bot_name)

	EventBus.match_started.emit("Deathmatch", "Arena")


func _spawn_bot(id: int, bot_name: String) -> void:
	var bot: CharacterBody2D = bot_scene.instantiate()
	bot.player_id = id
	bot.name = "Bot_%d" % id

	# Pick spawn point away from other players
	var enemy_positions: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group("players"):
		if node is CharacterBody2D:
			var character: CharacterBody2D = node as CharacterBody2D
			enemy_positions.append(character.global_position)

	bot.add_to_group("players")

	# Disable human input processing — bot controller writes input directly
	var input_mgr: Node = bot.get_node_or_null("InputManager")
	if input_mgr:
		input_mgr.set_process(false)

	# Add to tree first, THEN set position (global_position needs scene tree)
	get_parent().add_child(bot)

	if spawn_manager:
		bot.global_position = spawn_manager.get_spawn_point(enemy_positions)
	else:
		bot.global_position = Vector2(200 + id * 300, 820)

	_bots.append(bot)
	GameState.add_player(id, bot_name)
	print("[MatchManager] Spawned %s at %s" % [bot_name, str(bot.global_position)])


func _end_match() -> void:
	match_active = false
	GameState.current_state = GameState.MatchState.ENDED
	var results: Array = GameState.get_scoreboard()
	EventBus.match_ended.emit({"scoreboard": results, "duration": match_timer})
