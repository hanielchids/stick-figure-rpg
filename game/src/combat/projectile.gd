## A physics-based projectile (rockets, grenades).
## Spawned by ProjectileSpawner, flies in a direction, explodes on contact.
extends Area2D

var speed: float = 500.0
var damage: float = 90.0
var explosion_radius: float = 120.0
var knockback_force: float = 300.0
var lifetime: float = 5.0
var direction: Vector2 = Vector2.RIGHT
var weapon_name: String = ""
var owner_id: int = -1
var _gravity: float = 100.0
var _velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	_velocity = direction * speed
	body_entered.connect(_on_body_entered)

	# Collision setup
	collision_layer = Constants.LAYER_PROJECTILES
	collision_mask = Constants.LAYER_WORLD | Constants.LAYER_PLAYERS

	# Lifetime timer
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(_explode)

	# Visual
	var visual := ColorRect.new()
	visual.size = Vector2(8, 4)
	visual.position = Vector2(-4, -2)
	visual.color = Color(1.0, 0.4, 0.1)
	add_child(visual)

	# Trail particles
	var particles := GPUParticles2D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-direction.x, -direction.y, 0)
	mat.spread = 10.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 40.0
	mat.scale_min = 1.0
	mat.scale_max = 2.0
	mat.color = Color(1.0, 0.5, 0.1, 0.7)
	particles.process_material = mat
	particles.amount = 8
	particles.lifetime = 0.3
	add_child(particles)

	# Collision shape
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_velocity.y += _gravity * delta
	position += _velocity * delta
	rotation = _velocity.angle()
	lifetime -= delta


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.player_id == owner_id:
		return  # don't hit self
	_explode()


func _explode() -> void:
	if not is_inside_tree():
		return

	# Area damage
	if explosion_radius > 0:
		var space := get_world_2d().direct_space_state
		var shape_query := PhysicsShapeQueryParameters2D.new()
		var circle := CircleShape2D.new()
		circle.radius = explosion_radius
		shape_query.shape = circle
		shape_query.transform = Transform2D(0, global_position)
		shape_query.collision_mask = Constants.LAYER_PLAYERS

		var results := space.intersect_shape(shape_query, 16)
		for result in results:
			var collider = result.collider
			if collider is CharacterBody2D and collider.has_node("HealthSystem"):
				var dist := global_position.distance_to(collider.global_position)
				var falloff := 1.0 - clampf(dist / explosion_radius, 0.0, 1.0)
				var health: HealthSystem = collider.get_node("HealthSystem")
				health.take_damage(damage * falloff, owner_id, weapon_name)

				# Knockback
				var target: CharacterBody2D = collider as CharacterBody2D
				var kb_dir: Vector2 = (target.global_position - global_position).normalized()
				target.velocity += kb_dir * knockback_force * falloff

	# Explosion visual
	_spawn_explosion_visual()
	queue_free()


func _spawn_explosion_visual() -> void:
	var explosion := GPUParticles2D.new()
	explosion.emitting = true
	explosion.one_shot = true
	explosion.amount = 20
	explosion.lifetime = 0.4
	explosion.global_position = global_position

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 150.0
	mat.gravity = Vector3(0, 100, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(1.0, 0.5, 0.1, 0.9)
	explosion.process_material = mat

	get_tree().current_scene.add_child(explosion)
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(explosion.queue_free)
