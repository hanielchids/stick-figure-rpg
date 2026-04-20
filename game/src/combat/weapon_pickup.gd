## A weapon pickup in the world. Players walk over it to swap their current weapon.
## Respawns after a timer.
extends Area2D

@export var weapon_resource: WeaponDefinition
@export var respawn_time: float = Constants.WEAPON_PICKUP_RESPAWN

var is_available: bool = true
var _respawn_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = Constants.LAYER_PICKUPS
	collision_mask = Constants.LAYER_PLAYERS

	# Float animation
	var tween := create_tween().set_loops()
	tween.tween_property(visual, "position:y", -4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual, "position:y", 4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if not is_available:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_respawn()


func _on_body_entered(body: Node2D) -> void:
	if not is_available:
		return
	if not (body is CharacterBody2D and body.has_node("WeaponManager")):
		return

	var wm: WeaponManager = body.get_node("WeaponManager")
	var old_weapon := wm.equip_weapon(weapon_resource)

	var player_id: int = body.get("player_id") if body.get("player_id") != null else -1
	EventBus.weapon_picked_up.emit(player_id, weapon_resource.weapon_name)

	_hide_pickup()


func _hide_pickup() -> void:
	is_available = false
	_respawn_timer = respawn_time
	visual.visible = false
	collision.set_deferred("disabled", true)


func _respawn() -> void:
	is_available = true
	visual.visible = true
	collision.set_deferred("disabled", false)
	EventBus.pickup_spawned.emit("weapon", global_position)
