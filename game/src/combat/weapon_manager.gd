## Manages the player's weapons — equip, swap, fire, reload, ammo tracking.
## Attach as a child of the player node.
class_name WeaponManager
extends Node

signal weapon_changed(weapon: WeaponDefinition)
signal ammo_changed(current: int, max_ammo: int)
signal reload_started(duration: float)
signal reload_finished()
signal weapon_fired_signal(weapon: WeaponDefinition)

const MAX_WEAPONS: int = 2

var weapons: Array[WeaponDefinition] = []
var ammo: Array[int] = []  # current ammo per slot
var current_slot: int = 0
var is_reloading: bool = false

var _fire_timer: float = 0.0
var _reload_timer: float = 0.0
var _swap_cooldown: float = 0.0
var _swap_cooldown_duration: float = 0.3

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent()


func _process(delta: float) -> void:
	if _fire_timer > 0:
		_fire_timer -= delta
	if _swap_cooldown > 0:
		_swap_cooldown -= delta

	if is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0:
			_finish_reload()


func equip_weapon(definition: WeaponDefinition) -> WeaponDefinition:
	## Equips a weapon. If full, replaces current slot and returns the old weapon.
	## Returns null if weapon was added to an empty slot.
	var old_weapon: WeaponDefinition = null

	if weapons.size() < MAX_WEAPONS:
		weapons.append(definition)
		ammo.append(definition.ammo_capacity)
		current_slot = weapons.size() - 1
	else:
		old_weapon = weapons[current_slot]
		weapons[current_slot] = definition
		ammo[current_slot] = definition.ammo_capacity

	_cancel_reload()
	weapon_changed.emit(get_current_weapon())
	ammo_changed.emit(get_current_ammo(), get_current_weapon().ammo_capacity)
	return old_weapon


func swap_weapon() -> void:
	if weapons.size() < 2 or _swap_cooldown > 0:
		return

	_cancel_reload()
	current_slot = (current_slot + 1) % weapons.size()
	_swap_cooldown = _swap_cooldown_duration
	weapon_changed.emit(get_current_weapon())
	ammo_changed.emit(get_current_ammo(), get_current_weapon().ammo_capacity)


func try_fire(aim_direction: Vector2) -> bool:
	## Attempts to fire. Returns true if fired successfully.
	var weapon := get_current_weapon()
	if weapon == null or is_reloading or _fire_timer > 0 or _swap_cooldown > 0:
		return false

	# Check ammo (melee has unlimited: ammo_capacity == -1)
	if weapon.ammo_capacity >= 0:
		if ammo[current_slot] <= 0:
			start_reload()
			return false
		ammo[current_slot] -= 1
		ammo_changed.emit(ammo[current_slot], weapon.ammo_capacity)

	_fire_timer = weapon.get_fire_interval()
	weapon_fired_signal.emit(weapon)
	EventBus.weapon_fired.emit(player.player_id if player else -1, weapon.weapon_name)
	return true


func start_reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null or is_reloading:
		return
	if weapon.ammo_capacity < 0:  # melee, no reload
		return
	if ammo[current_slot] >= weapon.ammo_capacity:
		return

	is_reloading = true
	_reload_timer = weapon.reload_time
	reload_started.emit(weapon.reload_time)


func _finish_reload() -> void:
	var weapon := get_current_weapon()
	if weapon:
		ammo[current_slot] = weapon.ammo_capacity
		ammo_changed.emit(ammo[current_slot], weapon.ammo_capacity)
	is_reloading = false
	reload_finished.emit()


func _cancel_reload() -> void:
	is_reloading = false
	_reload_timer = 0.0


func get_current_weapon() -> WeaponDefinition:
	if current_slot >= 0 and current_slot < weapons.size():
		return weapons[current_slot]
	return null


func get_current_ammo() -> int:
	if current_slot >= 0 and current_slot < ammo.size():
		return ammo[current_slot]
	return 0


func has_weapon() -> bool:
	return weapons.size() > 0
