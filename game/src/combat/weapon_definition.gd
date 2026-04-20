## Data container for weapon stats. Each weapon type has one of these.
## Stored as .tres resource files for easy tuning without code changes.
class_name WeaponDefinition
extends Resource

enum WeaponType { HITSCAN, PROJECTILE, MELEE }

@export var weapon_name: String = ""
@export var type: WeaponType = WeaponType.HITSCAN
@export var damage: float = 10.0
@export var fire_rate: float = 5.0  # shots per second
@export var spread_angle: float = 0.0  # degrees
@export var range_distance: float = 1000.0
@export var ammo_capacity: int = 30
@export var reload_time: float = 1.5  # seconds
@export var projectile_speed: float = 0.0  # 0 = hitscan
@export var explosion_radius: float = 0.0  # 0 = no splash
@export var knockback_force: float = 0.0
@export var pellet_count: int = 1  # >1 for shotgun
@export var automatic: bool = true  # hold to fire vs click each shot


func get_fire_interval() -> float:
	return 1.0 / fire_rate if fire_rate > 0 else 0.1
