## Resolves melee attacks — short-range area check in aim direction.
class_name MeleeResolver
extends Node

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent()


func fire(weapon: WeaponDefinition, origin: Vector2, aim_direction: Vector2) -> void:
	# Check for targets in a short arc in front of the player
	var space := player.get_world_2d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = weapon.range_distance
	shape_query.shape = circle
	shape_query.transform = Transform2D(0, origin)
	shape_query.collision_mask = Constants.LAYER_PLAYERS

	var results := space.intersect_shape(shape_query, 8)
	for result in results:
		var collider = result.collider
		if collider == player:
			continue
		if not (collider is CharacterBody2D and collider.has_node("HealthSystem")):
			continue

		# Check if target is roughly in aim direction (120 degree cone)
		var target: CharacterBody2D = collider as CharacterBody2D
		var to_target: Vector2 = (target.global_position - origin).normalized()
		var dot: float = aim_direction.dot(to_target)
		if dot < 0.5:  # ~60 degrees each side
			continue

		var health: HealthSystem = target.get_node("HealthSystem")
		health.take_damage(weapon.damage, player.player_id, weapon.weapon_name)

		# Knockback
		if weapon.knockback_force > 0:
			target.velocity += to_target * weapon.knockback_force

	_spawn_swing_visual(origin, aim_direction, weapon.range_distance)


func _spawn_swing_visual(origin: Vector2, direction: Vector2, reach: float) -> void:
	## Quick arc slash visual.
	var arc := Line2D.new()
	arc.width = 2.0
	arc.default_color = Color(0.8, 0.8, 0.8, 0.7)
	arc.z_index = 5

	var base_angle := direction.angle()
	for i in 7:
		var t := float(i) / 6.0
		var angle: float = base_angle + lerpf(-0.6, 0.6, t)
		arc.add_point(origin + Vector2.from_angle(angle) * reach)

	player.get_tree().current_scene.add_child(arc)
	var timer := player.get_tree().create_timer(0.1)
	timer.timeout.connect(arc.queue_free)
