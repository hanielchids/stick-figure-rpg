## Resolves hitscan weapon shots — raycasting with spread, tracer visuals.
class_name HitscanResolver
extends Node

@export var tracer_color: Color = Color(1.0, 0.9, 0.3, 0.8)
@export var tracer_duration: float = 0.08

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent()


func fire(weapon: WeaponDefinition, origin: Vector2, base_direction: Vector2) -> void:
	for i in weapon.pellet_count:
		var direction := _apply_spread(base_direction, weapon.spread_angle)
		var end_point := origin + direction * weapon.range_distance

		# Raycast via physics space
		var space := player.get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(
			origin, end_point,
			Constants.LAYER_WORLD | Constants.LAYER_PLAYERS
		)
		query.exclude = [player.get_rid()]

		var result := space.intersect_ray(query)

		var hit_point: Vector2 = end_point
		if result:
			hit_point = result.position
			_apply_hit(result, weapon)

		_spawn_tracer(origin, hit_point)


func _apply_spread(direction: Vector2, spread_degrees: float) -> Vector2:
	if spread_degrees <= 0:
		return direction
	var spread_rad := deg_to_rad(spread_degrees)
	var angle_offset := randf_range(-spread_rad, spread_rad)
	return direction.rotated(angle_offset)


func _apply_hit(result: Dictionary, weapon: WeaponDefinition) -> void:
	var collider = result.collider

	# Check if we hit a player
	if collider is CharacterBody2D and collider.has_node("HealthSystem"):
		var health: HealthSystem = collider.get_node("HealthSystem")
		health.take_damage(weapon.damage, player.player_id, weapon.weapon_name)

		# Knockback
		if weapon.knockback_force > 0:
			var target: CharacterBody2D = collider as CharacterBody2D
			var kb_dir: Vector2 = (target.global_position - player.global_position).normalized()
			target.velocity += kb_dir * weapon.knockback_force


func _spawn_tracer(from: Vector2, to: Vector2) -> void:
	var tracer := Line2D.new()
	tracer.width = 1.5
	tracer.default_color = tracer_color
	tracer.add_point(from)
	tracer.add_point(to)
	tracer.z_index = 5

	# Add to scene tree (not as child of player, so it stays in world space)
	player.get_tree().current_scene.add_child(tracer)

	# Auto-remove after duration
	var timer := get_tree().create_timer(tracer_duration)
	timer.timeout.connect(tracer.queue_free)
