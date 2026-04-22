## Manages a match — spawns players/bots, tracks score, handles match flow.
## Works in both offline (single-player + bots) and online (multiplayer) modes.
extends Node

var bot_scene: PackedScene = preload("res://src/ai/bot.tscn")
var player_scene: PackedScene = preload("res://src/player/player.tscn")

@export var bot_count: int = 3
@export var score_limit: int = Constants.DEFAULT_SCORE_LIMIT
@export var time_limit: float = Constants.DEFAULT_TIME_LIMIT

var spawn_manager: SpawnPointManager
var match_active: bool = false
var match_timer: float = 0.0
var _bots: Array[CharacterBody2D] = []
var _players: Dictionary = {}  # peer_id -> CharacterBody2D


func _ready() -> void:
	for child in get_parent().get_children():
		if child is SpawnPointManager:
			spawn_manager = child

	if NetworkManager.is_online:
		NetworkManager.player_disconnected.connect(_on_player_disconnected)

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

	if NetworkManager.is_online:
		_start_online_match()
	else:
		_start_offline_match()

	EventBus.match_started.emit("Deathmatch", "Arena")


func _start_offline_match() -> void:
	# Register existing human player from the scene
	var human_player: Node = get_parent().get_node_or_null("Player")
	if human_player and human_player is CharacterBody2D:
		human_player.add_to_group("players")
		GameState.add_player(human_player.player_id, "Player")
		GameState.local_player_id = human_player.player_id
		_players[0] = human_player

	# Spawn bots
	var bot_names: Array[String] = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Ghost"]
	for i in bot_count:
		var bot_name: String = bot_names[i % bot_names.size()]
		_spawn_bot(i + 100, bot_name)  # bot IDs start at 100


func _start_online_match() -> void:
	# Only the server spawns players
	if not NetworkManager.is_server():
		return

	# Spawn the host player
	var host_id: int = multiplayer.get_unique_id()
	_spawn_network_player(host_id, "Host")
	GameState.local_player_id = host_id

	# Spawn connected peers
	for peer_id in NetworkManager.connected_peers:
		_spawn_network_player(peer_id, "Player_%d" % peer_id)

	# Spawn bots to fill
	var bot_names: Array[String] = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Ghost"]
	for i in bot_count:
		var bot_name: String = bot_names[i % bot_names.size()]
		_spawn_bot(i + 100, bot_name)


func _spawn_network_player(peer_id: int, player_name: String) -> void:
	var is_local: bool = (peer_id == multiplayer.get_unique_id())

	var character: CharacterBody2D
	if is_local:
		character = player_scene.instantiate()
	else:
		character = bot_scene.instantiate()  # no Camera2D for remote players
		# Remove BotController if present — this is a human, not a bot
		var bot_ctrl: Node = character.get_node_or_null("BotController")
		if bot_ctrl:
			bot_ctrl.queue_free()

	character.player_id = peer_id
	character.name = "Player_%d" % peer_id
	character.add_to_group("players")

	if NetworkManager.is_online:
		character.set_multiplayer_authority(peer_id)

	get_parent().add_child(character)

	if spawn_manager:
		var enemy_positions: Array[Vector2] = _get_enemy_positions(peer_id)
		character.global_position = spawn_manager.get_spawn_point(enemy_positions)
	else:
		character.global_position = Vector2(400 + peer_id % 4 * 300, 820)

	# Remote human players don't use local input
	if not is_local:
		var input_mgr: Node = character.get_node_or_null("InputManager")
		if input_mgr:
			input_mgr.set_process(false)

	_players[peer_id] = character
	GameState.add_player(peer_id, player_name)

	if is_local:
		GameState.local_player_id = peer_id


var _bot_spritesheets: Array[String] = [
	"res://assets/sprites/soldier_tilesheet.png",
	"res://assets/sprites/zombie_tilesheet.png",
	"res://assets/sprites/adventurer_tilesheet.png",
	"res://assets/sprites/female_tilesheet.png",
	"res://assets/sprites/player_tilesheet.png",
]


func _spawn_bot(bot_id: int, bot_name: String) -> void:
	var bot: CharacterBody2D = bot_scene.instantiate()
	bot.player_id = bot_id
	bot.name = "Bot_%d" % bot_id
	bot.add_to_group("players")

	# Assign unique sprite sheet to each bot
	var sheet_idx: int = _bots.size() % _bot_spritesheets.size()
	var sprite_char: Node = bot.get_node_or_null("SpriteCharacter")
	if sprite_char and sprite_char.has_method("setup_with_tilesheet"):
		sprite_char.setup_with_tilesheet(_bot_spritesheets[sheet_idx])

	var input_mgr: Node = bot.get_node_or_null("InputManager")
	if input_mgr:
		input_mgr.set_process(false)

	get_parent().add_child(bot)

	if spawn_manager:
		var enemy_positions: Array[Vector2] = _get_enemy_positions(bot_id)
		bot.global_position = spawn_manager.get_spawn_point(enemy_positions)
	else:
		bot.global_position = Vector2(150 + bot_id * 300, 820)

	_bots.append(bot)
	GameState.add_player(bot_id, bot_name)


func _get_enemy_positions(exclude_id: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group("players"):
		if node is CharacterBody2D:
			var character: CharacterBody2D = node as CharacterBody2D
			if character.player_id != exclude_id and not character.is_dead:
				positions.append(character.global_position)
	return positions


func _on_player_disconnected(peer_id: int) -> void:
	if _players.has(peer_id):
		var character: CharacterBody2D = _players[peer_id]
		if is_instance_valid(character):
			character.queue_free()
		_players.erase(peer_id)
		GameState.remove_player(peer_id)


func _end_match() -> void:
	match_active = false
	GameState.current_state = GameState.MatchState.ENDED
	var results: Array = GameState.get_scoreboard()
	EventBus.match_ended.emit({"scoreboard": results, "duration": match_timer})
	_submit_results_to_backend(results)


func _submit_results_to_backend(scoreboard: Array) -> void:
	if not ApiClient.is_logged_in:
		return

	var players_data: Array = []
	for i in scoreboard.size():
		var entry: Dictionary = scoreboard[i]
		var player_data: Dictionary = {
			"kills": entry["kills"],
			"deaths": entry["deaths"],
			"placement": i + 1,
			"xp_earned": entry["kills"] * 10 + (10 if i == 0 else 0),
		}
		# Only include user_id for real logged-in players
		if entry["id"] == GameState.local_player_id and ApiClient.current_user.has("id"):
			player_data["user_id"] = ApiClient.current_user["id"]
		else:
			player_data["bot_name"] = entry["name"]
		players_data.append(player_data)

	var match_data: Dictionary = {
		"map": "Arena",
		"mode": "Deathmatch",
		"duration_sec": int(match_timer),
		"players": players_data,
	}

	ApiClient.submit_match_results(match_data, func(response: Dictionary) -> void:
		if response.get("ok", false):
			print("[MatchManager] Results submitted to backend")
		else:
			print("[MatchManager] Failed to submit results: %s" % str(response.get("error", "")))
	)
