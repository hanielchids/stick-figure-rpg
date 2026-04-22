## Resolves hitscan weapon shots — raycasting with spread, sprite-based bullet visuals.
class_name HitscanResolver
extends Node

var player: CharacterBody2D

# Bullet sprite frames per weapon type
# Frame 1 = flying, later frames = impact animation
# Sprites are vertical (pointing up), rotated at runtime to match aim
var _bullet_frames: Dictionary = {}  # weapon_name -> Array[Texture2D]

const BULLET_MAP: Dictionary = {
	"Pistol": "Pistol-AR",
	"SMG": "Pistol-AR",
	"Shotgun": "Shotgun",
	"Sniper": "Snipe",
}

const BULLET_COUNTS: Dictionary = {
	"Pistol-AR": 8,
	"Shotgun": 7,
	"Snipe": 6,
}

const BULLET_SCALE: Dictionary = {
	"Pistol": 0.9,
	"SMG": 0.8,
	"Shotgun": 1.0,
	"Sniper": 1.2,
}


func _ready() -> void:
	player = get_parent()
	_preload_bullet_frames()


func _preload_bullet_frames() -> void:
	for weapon_name in BULLET_MAP:
		var prefix: String = BULLET_MAP[weapon_name]
		var count: int = BULLET_COUNTS.get(prefix, 6)
		var frames: Array[Texture2D] = []
		for i in range(1, count + 1):
			var path: String = "res://assets/sprites/bullets/%s%d.png" % [prefix, i]
			var tex: Texture2D = load(path)
			if tex:
				frames.append(tex)
		if not frames.is_empty():
			_bullet_frames[weapon_name] = frames


func fire(weapon: WeaponDefinition, origin: Vector2, base_direction: Vector2) -> void:
	for i in weapon.pellet_count:
		var direction: Vector2 = _apply_spread(base_direction, weapon.spread_angle)
		var end_point: Vector2 = origin + direction * weapon.range_distance

		var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			origin, end_point,
			Constants.LAYER_WORLD | Constants.LAYER_PLAYERS
		)
		query.exclude = [player.get_rid()]

		var result: Dictionary = space.intersect_ray(query)

		var hit_point: Vector2 = end_point
		if result:
			hit_point = result.position
			_apply_hit(result, weapon)

		_spawn_bullet(origin, hit_point, weapon.weapon_name)


func _apply_spread(direction: Vector2, spread_degrees: float) -> Vector2:
	if spread_degrees <= 0:
		return direction
	var spread_rad: float = deg_to_rad(spread_degrees)
	var angle_offset: float = randf_range(-spread_rad, spread_rad)
	return direction.rotated(angle_offset)


func _apply_hit(result: Dictionary, weapon: WeaponDefinition) -> void:
	var collider = result.collider

	if collider is CharacterBody2D and collider.has_node("HealthSystem"):
		var health: HealthSystem = collider.get_node("HealthSystem")
		health.take_damage(weapon.damage, player.player_id, weapon.weapon_name)

		if weapon.knockback_force > 0:
			var target: CharacterBody2D = collider as CharacterBody2D
			var kb_dir: Vector2 = (target.global_position - player.global_position).normalized()
			target.velocity += kb_dir * weapon.knockback_force


func _spawn_bullet(from: Vector2, to: Vector2, weapon_name: String) -> void:
	var scene_root: Node = player.get_tree().current_scene

	var bullet := SpriteBullet.new()
	bullet.start_pos = from
	bullet.end_pos = to

	if _bullet_frames.has(weapon_name):
		bullet.frames = _bullet_frames[weapon_name]
	bullet.scale_factor = BULLET_SCALE.get(weapon_name, 0.4)

	scene_root.add_child(bullet)


## Sprite-based bullet that flies from start to end, then plays impact animation.
class SpriteBullet extends Node2D:
	var start_pos: Vector2 = Vector2.ZERO
	var end_pos: Vector2 = Vector2.ZERO
	var frames: Array[Texture2D] = []
	var scale_factor: float = 0.4

	var _sprite: Sprite2D
	var _progress: float = 0.0
	var _speed: float = 4.0  # slower so you can see them
	var _impact_frame: int = 0
	var _impact_timer: float = 0.0
	var _state: int = 0  # 0 = flying, 1 = impact, 2 = done

	func _ready() -> void:
		global_position = start_pos
		z_index = 5

		_sprite = Sprite2D.new()
		_sprite.scale = Vector2(scale_factor, scale_factor)
		add_child(_sprite)

		# Set flying frame
		if not frames.is_empty():
			_sprite.texture = frames[0]

		# Rotate sprite to match travel direction
		# Sprites point UP, so subtract 90° to make them point RIGHT
		var direction: Vector2 = (end_pos - start_pos).normalized()
		_sprite.rotation = direction.angle() + PI / 2

	func _process(delta: float) -> void:
		match _state:
			0:  # Flying
				_progress += delta * _speed
				if _progress >= 1.0:
					_progress = 1.0
					global_position = end_pos
					_state = 1
					_impact_frame = 1
					# Keep the same rotation — impact faces travel direction
					_sprite.scale = Vector2(scale_factor * 1.8, scale_factor * 1.8)
				else:
					global_position = start_pos.lerp(end_pos, _progress)

			1:  # Impact animation
				_impact_timer += delta
				if _impact_timer > 0.04:
					_impact_timer = 0.0
					_impact_frame += 1
					if _impact_frame < frames.size():
						_sprite.texture = frames[_impact_frame]
					else:
						_state = 2
						queue_free()
