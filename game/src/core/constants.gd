## Game-wide constants. Access via the Constants autoload singleton.
extends Node

# Physics
const GRAVITY: float = 980.0
const MAX_FALL_SPEED: float = 600.0

# Player movement
const RUN_SPEED: float = 200.0
const JUMP_VELOCITY: float = -350.0
const CROUCH_SPEED_MULT: float = 0.5
const CROUCH_HITBOX_SCALE: float = 0.6

# Jetpack
const JETPACK_THRUST: float = -500.0
const JETPACK_FUEL_MAX: float = 100.0
const JETPACK_DRAIN_RATE: float = 30.0  # per second
const JETPACK_RECHARGE_RATE: float = 25.0  # per second, while grounded
const JETPACK_HORIZONTAL_BOOST: float = 50.0

# Wall hanging
const WALL_HANG_SLIDE_SPEED: float = 20.0
const WALL_JUMP_VELOCITY: Vector2 = Vector2(250.0, -300.0)

# Combat
const DEFAULT_MAX_HP: float = 100.0
const RESPAWN_TIME: float = 3.0
const INVULNERABILITY_TIME: float = 2.0
const HEADSHOT_MULTIPLIER: float = 1.5

# Pickups
const HEALTH_PICKUP_AMOUNT: float = 25.0
const HEALTH_PICKUP_RESPAWN: float = 20.0
const WEAPON_PICKUP_RESPAWN: float = 15.0

# Match (var instead of const so settings screen can change them)
var DEFAULT_SCORE_LIMIT: int = 20
var DEFAULT_TIME_LIMIT: float = 300.0

# Physics layers
const LAYER_WORLD: int = 1
const LAYER_PLAYERS: int = 2
const LAYER_PROJECTILES: int = 4
const LAYER_PICKUPS: int = 8
const LAYER_KILLZONE: int = 16
