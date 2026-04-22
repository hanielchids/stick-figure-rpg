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


func _find_target() -> void:
	var best: CharacterBody2D = null
	var best_dist: float = difficulty.detection_range

	for node in get_tree().get_nodes_in_group("players"):
		if not node is CharacterBody2D:
			continue
		var character: CharacterBody2D = node as CharacterBody2D
		if character == player or character.is_dead:
			continue

		var dist: float = player.global_position.distance_to(character.global_position)
		if dist < best_dist:
			best_dist = dist
			best = character

	target = best


func _do_patrol(delta: float) -> void:
	_patrol_timer -= delta

	if _patrol_timer <= 0:
		_patrol_dir = -_patrol_dir
		_patrol_timer = randf_range(1.5, 4.0)

		# Randomly jetpack during patrol
		if randf() < 0.3:
			_jetpack_timer = randf_range(0.5, 1.5)

	input_manager.current_input.move_direction = _patrol_dir

	# Jetpack up sometimes to explore
	if _jetpack_timer > 0 and player.jetpack_fuel > 10:
		input_manager.current_input.jetpack_held = true


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

	# Jetpack to match target height
	if to_target.y < -80 and player.jetpack_fuel > 15:
		input_manager.current_input.jetpack_held = true
	elif randf() < difficulty.aggression * 0.05:
		# Random jetpack bursts for unpredictability
		input_manager.current_input.jetpack_held = true

	# --- FIRE ---
	if _fire_cooldown <= 0:
		input_manager.current_input.fire_pressed = true
		input_manager.current_input.fire_held = true
		_fire_cooldown = difficulty.reaction_time_sec

	# Keep holding fire for automatic weapons
	var weapon: WeaponDefinition = weapon_manager.get_current_weapon()
	if weapon and weapon.automatic and _fire_cooldown < difficulty.reaction_time_sec * 0.5:
		input_manager.current_input.fire_held = true

	# Reload when empty
	if weapon and weapon.ammo_capacity >= 0 and weapon_manager.get_current_ammo() <= 0:
		input_manager.current_input.reload_pressed = true


func _do_retreat(_delta: float) -> void:
	if target and is_instance_valid(target):
		# Run away from target
		var away: float = -signf(target.global_position.x - player.global_position.x)
		input_manager.current_input.move_direction = away

		# Jetpack up to escape
		if player.jetpack_fuel > 20 and randf() < 0.1:
			input_manager.current_input.jetpack_held = true
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
