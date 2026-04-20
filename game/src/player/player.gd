## Main player controller. Handles movement, jetpack, wall-hanging, and crouch.
## Uses CharacterBody2D with server-reconciliation-ready architecture.
extends CharacterBody2D

enum State { IDLE, RUNNING, JUMPING, FALLING, JETPACKING, WALL_HANGING, CROUCHING, DEAD }

@export var player_id: int = 0

var current_state: State = State.IDLE
var jetpack_fuel: float = Constants.JETPACK_FUEL_MAX
var facing_right: bool = true
var is_dead: bool = false

@onready var input_manager: InputManager = $InputManager
@onready var sprite: Sprite2D = $Sprite2D
@onready var standing_collision: CollisionShape2D = $StandingCollision
@onready var crouching_collision: CollisionShape2D = $CrouchingCollision
@onready var wall_raycast_right: RayCast2D = $WallRaycastRight
@onready var wall_raycast_left: RayCast2D = $WallRaycastLeft
@onready var health_system: HealthSystem = $HealthSystem
@onready var weapon_manager: WeaponManager = $WeaponManager

var _respawn_timer: float = 0.0
var _spawn_position: Vector2


func _ready() -> void:
	crouching_collision.disabled = true
	_spawn_position = global_position
	health_system.owner_id = player_id
	health_system.died.connect(_on_died)

	# Give default weapon (pistol)
	var pistol := load("res://assets/weapons/pistol.tres") as WeaponDefinition
	if pistol:
		weapon_manager.equip_weapon(pistol)


func _physics_process(delta: float) -> void:
	if is_dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			respawn()
		return

	var input := input_manager.current_input

	_update_facing(input)

	match current_state:
		State.IDLE, State.RUNNING:
			_state_ground(input, delta)
		State.JUMPING, State.FALLING:
			_state_air(input, delta)
		State.JETPACKING:
			_state_jetpack(input, delta)
		State.WALL_HANGING:
			_state_wall_hang(input, delta)
		State.CROUCHING:
			_state_crouch(input, delta)

	# Recharge jetpack fuel while grounded
	if is_on_floor() and current_state != State.JETPACKING:
		jetpack_fuel = minf(jetpack_fuel + Constants.JETPACK_RECHARGE_RATE * delta, Constants.JETPACK_FUEL_MAX)

	move_and_slide()


func _update_facing(input: InputManager.PlayerInput) -> void:
	if input.aim_position.x > global_position.x:
		facing_right = true
		sprite.flip_h = false
	else:
		facing_right = false
		sprite.flip_h = true


func _state_ground(input: InputManager.PlayerInput, delta: float) -> void:
	if not is_on_floor():
		_transition_to(State.FALLING)
		return

	# Jump (reset vertical velocity)
	if input.jump_pressed:
		velocity.y = Constants.JUMP_VELOCITY
		_transition_to(State.JUMPING)
		return

	# Jetpack (reset vertical velocity so gravity doesn't fight launch)
	if input.jetpack_held and jetpack_fuel > 0:
		velocity.y = 0
		_transition_to(State.JETPACKING)
		return

	# Crouch
	if input.crouch_held:
		_transition_to(State.CROUCHING)
		return

	# Apply gravity to maintain floor contact (only if staying grounded)
	velocity.y = Constants.GRAVITY * delta

	# Horizontal movement
	velocity.x = input.move_direction * Constants.RUN_SPEED

	if absf(velocity.x) > 0.1:
		_transition_to(State.RUNNING)
	else:
		_transition_to(State.IDLE)


func _state_air(input: InputManager.PlayerInput, delta: float) -> void:
	# Apply gravity
	velocity.y = minf(velocity.y + Constants.GRAVITY * delta, Constants.MAX_FALL_SPEED)

	# Jetpack activation mid-air
	if input.jetpack_held and jetpack_fuel > 0:
		_transition_to(State.JETPACKING)
		return

	# Wall hang check (only while falling)
	if velocity.y > 0 and _check_wall_contact():
		_transition_to(State.WALL_HANGING)
		return

	# Air control
	velocity.x = input.move_direction * Constants.RUN_SPEED

	# Variable jump height — release jump early to fall sooner
	if current_state == State.JUMPING and not input.jump_held and velocity.y < 0:
		velocity.y *= 0.5

	# Transition to falling
	if velocity.y > 0 and current_state == State.JUMPING:
		_transition_to(State.FALLING)

	# Landed
	if is_on_floor():
		_transition_to(State.IDLE)


func _state_jetpack(input: InputManager.PlayerInput, delta: float) -> void:
	# Drain fuel
	jetpack_fuel -= Constants.JETPACK_DRAIN_RATE * delta

	if jetpack_fuel <= 0 or not input.jetpack_held:
		jetpack_fuel = maxf(jetpack_fuel, 0)
		_transition_to(State.FALLING)
		return

	# Thrust
	velocity.y += Constants.JETPACK_THRUST * delta

	# Horizontal control with slight boost
	velocity.x = input.move_direction * (Constants.RUN_SPEED + Constants.JETPACK_HORIZONTAL_BOOST)

	# Apply some gravity to fight against (makes it feel weighted)
	velocity.y += Constants.GRAVITY * 0.4 * delta

	# Cap upward speed
	velocity.y = maxf(velocity.y, -400.0)

	if is_on_floor():
		_transition_to(State.IDLE)


func _state_wall_hang(input: InputManager.PlayerInput, delta: float) -> void:
	# Slow slide down wall
	velocity.y = Constants.WALL_HANG_SLIDE_SPEED
	velocity.x = 0

	# Jump off wall
	if input.jump_pressed:
		var wall_normal := _get_wall_normal()
		velocity = Vector2(
			wall_normal.x * Constants.WALL_JUMP_VELOCITY.x,
			Constants.WALL_JUMP_VELOCITY.y
		)
		_transition_to(State.JUMPING)
		return

	# Jetpack off wall
	if input.jetpack_held and jetpack_fuel > 0:
		_transition_to(State.JETPACKING)
		return

	# Let go
	if input.crouch_held or not _check_wall_contact():
		_transition_to(State.FALLING)
		return

	if is_on_floor():
		_transition_to(State.IDLE)


func _state_crouch(input: InputManager.PlayerInput, delta: float) -> void:
	# Apply just enough gravity to maintain floor contact
	velocity.y = Constants.GRAVITY * delta
	if not is_on_floor():
		_transition_to(State.FALLING)
		return

	if not input.crouch_held:
		_transition_to(State.IDLE)
		return

	# Slow movement while crouching
	velocity.x = input.move_direction * Constants.RUN_SPEED * Constants.CROUCH_SPEED_MULT

	# Can jump out of crouch
	if input.jump_pressed:
		velocity.y = Constants.JUMP_VELOCITY
		_transition_to(State.JUMPING)
		return


func _transition_to(new_state: State) -> void:
	if current_state == new_state:
		return

	var old_state := current_state
	current_state = new_state

	# Handle collision shape swaps
	match new_state:
		State.CROUCHING:
			standing_collision.disabled = true
			crouching_collision.disabled = false
		_:
			if old_state == State.CROUCHING:
				standing_collision.disabled = false
				crouching_collision.disabled = true


func _check_wall_contact() -> bool:
	return wall_raycast_right.is_colliding() or wall_raycast_left.is_colliding()


func _get_wall_normal() -> Vector2:
	if wall_raycast_right.is_colliding():
		return Vector2.LEFT
	elif wall_raycast_left.is_colliding():
		return Vector2.RIGHT
	return Vector2.ZERO


func _on_died(_killer_id: int) -> void:
	is_dead = true
	_transition_to(State.DEAD)
	velocity = Vector2.ZERO
	_respawn_timer = Constants.RESPAWN_TIME
	sprite.modulate = Color(1, 1, 1, 0.3)


func respawn() -> void:
	is_dead = false
	global_position = _spawn_position
	velocity = Vector2.ZERO
	jetpack_fuel = Constants.JETPACK_FUEL_MAX
	health_system.respawn()
	_transition_to(State.IDLE)
	sprite.modulate = Color(1, 1, 1, 1)
	EventBus.player_respawned.emit(player_id, global_position)
