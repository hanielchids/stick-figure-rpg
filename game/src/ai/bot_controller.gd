## Bot AI controller — aggressive, mobile, combat-ready.
## Replaces human input with AI decisions.
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
var _move_speed_mult: float = 0.6  # bots move at 60% of player speed


func _ready() -> void:
	player = get_parent()
	input_manager = player.get_node("InputManager")
	weapon_manager = player.get_node("WeaponManager")
	health_system = player.get_node("HealthSystem")

	if difficulty == null:
		difficulty = load("res://assets/ai/medium.tres") as DifficultyProfile

	_patrol_dir = [-1.0, 1.0][randi() % 2]
	_patrol_timer = randf_range(1.0, 3.0)


func _process(delta: float) -> void:
	if player.is_dead:
		_clear_all_input()
		return

	_state_timer += delta
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_jump_cooldown = maxf(_jump_cooldown - delta, 0.0)
	_jetpack_timer -= delta

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

	# Apply speed multiplier — bots move slower than players
	input_manager.current_input.move_direction *= _move_speed_mult


func _find_target() -> void:
	# Priority 1: target human players (no BotController child)
	# Priority 2: target other bots only if no humans found
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
			# Human player — always prioritize, no range limit
			if dist < best_human_dist:
				best_human_dist = dist
				best_human = character
		else:
			# Other bot — fallback target within detection range
			if dist < best_bot_dist:
				best_bot_dist = dist
				best_bot = character

	# Prefer humans over bots
	if best_human:
		target = best_human
	else:
		target = best_bot


func _do_patrol(delta: float) -> void:
	_patrol_timer -= delta

	if _patrol_timer <= 0:
		_patrol_dir = -_patrol_dir
		_patrol_timer = randf_range(1.0, 2.5)

		# Frequently jetpack during patrol to explore the map
		_jetpack_timer = randf_range(0.3, 1.2)

	input_manager.current_input.move_direction = _patrol_dir

	# Jetpack up to explore platforms
	if _jetpack_timer > 0 and player.jetpack_fuel > 5:
		input_manager.current_input.jetpack_held = true

	# Random jumps while patrolling
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

	# --- MOVEMENT ---
	if dist < 120:
		# Very close — back up and shoot
		input_manager.current_input.move_direction = -signf(to_target.x)
	elif dist > 350:
		# Far — rush toward target
		input_manager.current_input.move_direction = signf(to_target.x)
	else:
		# Good range — strafe
		if _state_timer > 1.0:
			_patrol_dir = -_patrol_dir
			_state_timer = 0.0
		input_manager.current_input.move_direction = _patrol_dir

	# Jetpack aggressively — match target height or gain advantage
	if to_target.y < -50 and player.jetpack_fuel > 5:
		input_manager.current_input.jetpack_held = true
	elif randf() < difficulty.aggression * 0.15:
		input_manager.current_input.jetpack_held = true

	# Jump while fighting
	if player.is_on_floor() and randf() < 0.05:
		input_manager.current_input.jump_pressed = true
		input_manager.current_input.jump_held = true

	# --- FIRE ---
	var weapon: WeaponDefinition = weapon_manager.get_current_weapon()

	# Always hold fire when engaging (for automatic weapons)
	input_manager.current_input.fire_held = true

	# Press fire on cooldown (for semi-auto weapons)
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
		# Run away from target
		var away: float = -signf(target.global_position.x - player.global_position.x)
		input_manager.current_input.move_direction = away

		# Jetpack away aggressively
		if player.jetpack_fuel > 5:
			input_manager.current_input.jetpack_held = true

		# Jump to get away faster
		if player.is_on_floor():
			input_manager.current_input.jump_pressed = true
			input_manager.current_input.jump_held = true
	else:
		input_manager.current_input.move_direction = _patrol_dir

	# Exit retreat when health recovers
	if health_system.get_hp_percent() > 0.6:
		current_state = BotState.PATROL


func _handle_obstacles() -> void:
	# Jump when hitting a wall
	if player.is_on_wall() and _jump_cooldown <= 0:
		if player.is_on_floor():
			input_manager.current_input.jump_pressed = true
			input_manager.current_input.jump_held = true
			_jump_cooldown = 0.5
		elif player.jetpack_fuel > 10:
			# Jetpack over obstacles
			input_manager.current_input.jetpack_held = true

	# Jump at edges (don't fall off platforms when patrolling)
	if player.is_on_floor() and _jump_cooldown <= 0:
		# Random jumps to move around the map
		if randf() < 0.005:
			input_manager.current_input.jump_pressed = true
			_jump_cooldown = 1.0


func _clear_all_input() -> void:
	input_manager.current_input.move_direction = 0.0
	input_manager.current_input.jump_pressed = false
	input_manager.current_input.jump_held = false
	input_manager.current_input.jetpack_held = false
	input_manager.current_input.fire_pressed = false
	input_manager.current_input.fire_held = false
	input_manager.current_input.reload_pressed = false
