## Bot AI controller — aggressive, mobile, combat-ready.
## Prioritizes human players over other bots.
## Uses smart pathfinding: jetpack up, drop down, navigate around obstacles.
class_name BotController
extends Node

enum BotState { PATROL, ENGAGE, RETREAT }

@export var difficulty: DifficultyProfile

var player: CharacterBody2D
var input_manager: InputManager
var weapon_manager: WeaponManager
var health_system: HealthSystem

var current_state: BotState = BotState.PATROL
var target: CharacterBody2D = null
var _state_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _aim_noise: float = 0.0
var _patrol_dir: float = 1.0
var _patrol_timer: float = 0.0
var _jetpack_timer: float = 0.0
var _jump_cooldown: float = 0.0
var _stuck_timer: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _move_speed_mult: float = 0.6


func _ready() -> void:
	player = get_parent()
	input_manager = player.get_node("InputManager")
	weapon_manager = player.get_node("WeaponManager")
	health_system = player.get_node("HealthSystem")

	if difficulty == null:
		difficulty = load("res://assets/ai/medium.tres") as DifficultyProfile

	_patrol_dir = [-1.0, 1.0][randi() % 2]
	_patrol_timer = randf_range(1.0, 3.0)
	_last_position = player.global_position


func _process(delta: float) -> void:
	if player.is_dead:
		_clear_all_input()
		return

	_state_timer += delta
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_jump_cooldown = maxf(_jump_cooldown - delta, 0.0)
	_jetpack_timer -= delta

	# Stuck detection — if barely moved in 1 second, try to unstick
	_stuck_timer += delta
	if _stuck_timer > 1.0:
		var moved: float = player.global_position.distance_to(_last_position)
		if moved < 5.0:
			_unstick()
		_last_position = player.global_position
		_stuck_timer = 0.0

	# Always look for targets
	_find_target()

	# Evaluate state
	if health_system.get_hp_percent() < difficulty.retreat_health_threshold and target:
		current_state = BotState.RETREAT
	elif target:
		current_state = BotState.ENGAGE
	else:
		current_state = BotState.PATROL

	# Reset inputs each frame
	_clear_all_input()

	# Execute current state
	match current_state:
		BotState.PATROL:
			_do_patrol(delta)
		BotState.ENGAGE:
			_do_engage(delta)
		BotState.RETREAT:
			_do_retreat(delta)

	# Always handle navigation obstacles
	_handle_obstacles()

	# Apply speed multiplier
	input_manager.current_input.move_direction *= _move_speed_mult


func _find_target() -> void:
	var best_human: CharacterBody2D = null
	var best_human_dist: float = INF
	var best_bot: CharacterBody2D = null
	var best_bot_dist: float = difficulty.detection_range

	for node in get_tree().get_nodes_in_group("players"):
		if not node is CharacterBody2D:
			continue
		var character: CharacterBody2D = node as CharacterBody2D
		if character == player or character.is_dead:
			continue

		var dist: float = player.global_position.distance_to(character.global_position)
		var is_bot: bool = character.get_node_or_null("BotController") != null

		if not is_bot:
			if dist < best_human_dist:
				best_human_dist = dist
				best_human = character
		else:
			if dist < best_bot_dist:
				best_bot_dist = dist
				best_bot = character

	if best_human:
		target = best_human
	else:
		target = best_bot


func _do_patrol(delta: float) -> void:
	_patrol_timer -= delta

	if _patrol_timer <= 0:
		_patrol_dir = -_patrol_dir
		_patrol_timer = randf_range(1.0, 2.5)
		_jetpack_timer = randf_range(0.3, 1.2)

	input_manager.current_input.move_direction = _patrol_dir

	# Jetpack to explore platforms
	if _jetpack_timer > 0 and player.jetpack_fuel > 5:
		input_manager.current_input.jetpack_held = true

	# Random jumps
	if player.is_on_floor() and randf() < 0.02:
		input_manager.current_input.jump_pressed = true
		input_manager.current_input.jump_held = true


func _do_engage(delta: float) -> void:
	if not target or not is_instance_valid(target) or target.is_dead:
		target = null
		return

	var to_target: Vector2 = target.global_position - player.global_position
	var dist: float = to_target.length()

	# --- AIM ---
	_aim_noise = lerpf(_aim_noise, randf_range(-difficulty.aim_noise_deg, difficulty.aim_noise_deg), delta * 5.0)
	var aim_pos: Vector2 = target.global_position + Vector2(0, -20)
	aim_pos += Vector2.from_angle(randf() * TAU) * _aim_noise
	input_manager.current_input.aim_position = aim_pos

	# --- SMART PATHFINDING TO TARGET ---
	_navigate_to(target.global_position, dist)

	# --- FIRE ---
	var weapon: WeaponDefinition = weapon_manager.get_current_weapon()
	input_manager.current_input.fire_held = true
	if _fire_cooldown <= 0:
		input_manager.current_input.fire_pressed = true
		_fire_cooldown = difficulty.reaction_time_sec * randf_range(0.5, 1.0)

	# Reload when empty
	if weapon and weapon.ammo_capacity >= 0 and weapon_manager.get_current_ammo() <= 0:
		input_manager.current_input.fire_held = false
		input_manager.current_input.fire_pressed = false
		input_manager.current_input.reload_pressed = true


func _do_retreat(_delta: float) -> void:
	if target and is_instance_valid(target):
		var away: float = -signf(target.global_position.x - player.global_position.x)
		input_manager.current_input.move_direction = away

		# Jetpack away
		if player.jetpack_fuel > 5:
			input_manager.current_input.jetpack_held = true
		if player.is_on_floor():
			input_manager.current_input.jump_pressed = true
			input_manager.current_input.jump_held = true
	else:
		input_manager.current_input.move_direction = _patrol_dir

	if health_system.get_hp_percent() > 0.6:
		current_state = BotState.PATROL


func _navigate_to(target_pos: Vector2, dist: float) -> void:
	## Smart navigation that handles vertical movement properly.
	var to_target: Vector2 = target_pos - player.global_position
	var height_diff: float = to_target.y  # negative = target is above

	# --- HORIZONTAL ---
	if dist < 120:
		# Close range — strafe while shooting
		if _state_timer > 1.0:
			_patrol_dir = -_patrol_dir
			_state_timer = 0.0
		input_manager.current_input.move_direction = _patrol_dir
	else:
		# Move toward target
		input_manager.current_input.move_direction = signf(to_target.x)

	# --- VERTICAL ---
	if height_diff < -30:
		# Target is ABOVE — need to go up
		if player.is_on_floor() and _jump_cooldown <= 0:
			# Jump first
			input_manager.current_input.jump_pressed = true
			input_manager.current_input.jump_held = true
			_jump_cooldown = 0.3
		elif player.jetpack_fuel > 5:
			# Jetpack up
			input_manager.current_input.jetpack_held = true
	elif height_diff > 100:
		# Target is FAR BELOW — drop down
		# Move off the edge of the current platform
		input_manager.current_input.move_direction = signf(to_target.x)
		# Don't jump — just walk off
	elif height_diff > 30 and height_diff < 100:
		# Target is slightly below — can jump toward them
		if player.is_on_floor() and _jump_cooldown <= 0:
			input_manager.current_input.jump_pressed = true
			_jump_cooldown = 0.5

	# Random combat jetpack bursts for unpredictability
	if dist > 100 and randf() < difficulty.aggression * 0.08:
		input_manager.current_input.jetpack_held = true


func _handle_obstacles() -> void:
	# Hit a wall — jump or jetpack over it
	if player.is_on_wall():
		if player.is_on_floor() and _jump_cooldown <= 0:
			input_manager.current_input.jump_pressed = true
			input_manager.current_input.jump_held = true
			_jump_cooldown = 0.3
		elif player.jetpack_fuel > 10:
			input_manager.current_input.jetpack_held = true

	# At the edge of the map — turn around
	if player.global_position.x < 60:
		input_manager.current_input.move_direction = 1.0
		_patrol_dir = 1.0
	elif player.global_position.x > 1540:
		input_manager.current_input.move_direction = -1.0
		_patrol_dir = -1.0


func _unstick() -> void:
	## Called when bot hasn't moved much — try to break free.
	# Reverse direction
	_patrol_dir = -_patrol_dir
	# Jump
	if player.is_on_floor():
		input_manager.current_input.jump_pressed = true
		input_manager.current_input.jump_held = true
	# Jetpack burst
	if player.jetpack_fuel > 20:
		_jetpack_timer = 0.8


func _clear_all_input() -> void:
	input_manager.current_input.move_direction = 0.0
	input_manager.current_input.jump_pressed = false
	input_manager.current_input.jump_held = false
	input_manager.current_input.jetpack_held = false
	input_manager.current_input.fire_pressed = false
	input_manager.current_input.fire_held = false
	input_manager.current_input.reload_pressed = false
