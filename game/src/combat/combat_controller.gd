## Orchestrates combat for a player — reads fire/reload/swap input,
## delegates to weapon manager and the appropriate resolver.
## Attach as child of the player node.
class_name CombatController
extends Node

var player: CharacterBody2D
var weapon_manager: WeaponManager
var hitscan_resolver: HitscanResolver
var melee_resolver: MeleeResolver
var input_manager: InputManager

var _muzzle_offset: Vector2 = Vector2(12, -20)  # relative to player origin


func _ready() -> void:
	player = get_parent()
	weapon_manager = player.get_node("WeaponManager")
	hitscan_resolver = player.get_node("HitscanResolver")
	melee_resolver = player.get_node("MeleeResolver")
	input_manager = player.get_node("InputManager")


func _process(_delta: float) -> void:
	if not player or player.is_dead:
		return

	var input := input_manager.current_input

	# Swap weapon
	if input.swap_weapon_pressed:
		weapon_manager.swap_weapon()

	# Reload
	if input.reload_pressed:
		weapon_manager.start_reload()

	# Fire
	var weapon := weapon_manager.get_current_weapon()
	if weapon == null:
		return

	var should_fire := false
	if weapon.automatic:
		should_fire = input.fire_held
	else:
		should_fire = input.fire_pressed

	if should_fire:
		var aim_dir := input_manager.get_aim_direction(player.global_position)
		if weapon_manager.try_fire(aim_dir):
			_execute_fire(weapon, aim_dir)


func _execute_fire(weapon: WeaponDefinition, aim_direction: Vector2) -> void:
	var muzzle_pos := player.global_position + Vector2(
		_muzzle_offset.x * (1 if player.facing_right else -1),
		_muzzle_offset.y
	)

	match weapon.type:
		WeaponDefinition.WeaponType.HITSCAN:
			hitscan_resolver.fire(weapon, muzzle_pos, aim_direction)
			_trigger_screen_shake(2.0)
		WeaponDefinition.WeaponType.PROJECTILE:
			_spawn_projectile(weapon, muzzle_pos, aim_direction)
			_trigger_screen_shake(4.0)
		WeaponDefinition.WeaponType.MELEE:
			melee_resolver.fire(weapon, muzzle_pos, aim_direction)
			_trigger_screen_shake(3.0)


func _spawn_projectile(weapon: WeaponDefinition, origin: Vector2, direction: Vector2) -> void:
	var proj_scene := preload("res://src/combat/projectile.tscn")
	var proj: Area2D = proj_scene.instantiate()
	proj.global_position = origin
	proj.direction = direction
	proj.speed = weapon.projectile_speed
	proj.damage = weapon.damage
	proj.explosion_radius = weapon.explosion_radius
	proj.knockback_force = weapon.knockback_force
	proj.weapon_name = weapon.weapon_name
	proj.owner_id = player.player_id
	player.get_tree().current_scene.add_child(proj)


func _trigger_screen_shake(intensity: float) -> void:
	var camera = player.get_node_or_null("Camera2D")
	if camera and camera.has_method("shake"):
		camera.shake(intensity)
