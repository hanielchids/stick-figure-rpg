## Health component. Attach to any entity that can take damage.
class_name HealthSystem
extends Node

signal health_changed(current_hp: float, max_hp: float)
signal died(killer_id: int)
signal damage_taken(amount: float, from_id: int)

@export var max_hp: float = Constants.DEFAULT_MAX_HP

var current_hp: float
var is_dead: bool = false
var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0

var owner_id: int = -1  # player_id of whoever owns this health


func _ready() -> void:
	current_hp = max_hp


func _process(delta: float) -> void:
	if _invulnerability_timer > 0:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0:
			is_invulnerable = false


func take_damage(amount: float, attacker_id: int = -1, weapon_name: String = "") -> void:
	if is_dead or is_invulnerable:
		return

	current_hp = maxf(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	damage_taken.emit(amount, attacker_id)
	EventBus.player_damaged.emit(owner_id, attacker_id, amount, weapon_name)

	if current_hp <= 0:
		_die(attacker_id, weapon_name)


func heal(amount: float) -> void:
	if is_dead:
		return
	current_hp = minf(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func _die(killer_id: int, weapon_name: String) -> void:
	is_dead = true
	died.emit(killer_id)
	EventBus.player_died.emit(owner_id, killer_id, weapon_name)


func respawn() -> void:
	is_dead = false
	current_hp = max_hp
	is_invulnerable = true
	_invulnerability_timer = Constants.INVULNERABILITY_TIME
	health_changed.emit(current_hp, max_hp)


func get_hp_percent() -> float:
	return current_hp / max_hp if max_hp > 0 else 0.0
