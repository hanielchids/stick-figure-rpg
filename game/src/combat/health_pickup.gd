## A health pickup in the world. Players walk over it to heal.
## Respawns after a timer.
extends Area2D

@export var heal_amount: float = Constants.HEALTH_PICKUP_AMOUNT
@export var respawn_time: float = Constants.HEALTH_PICKUP_RESPAWN

var is_available: bool = true
var _respawn_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = Constants.LAYER_PICKUPS
	collision_mask = Constants.LAYER_PLAYERS

	# Replace default visuals with a drawn health pack
	_setup_visual()

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
	if not (body is CharacterBody2D and body.has_node("HealthSystem")):
		return

	var health: HealthSystem = body.get_node("HealthSystem")
	if health.current_hp >= health.max_hp:
		return  # already full HP

	health.heal(heal_amount)
	var player_id: int = body.get("player_id") if body.get("player_id") != null else -1
	EventBus.health_picked_up.emit(player_id, heal_amount)
	SoundManager.play_sfx("pickup")

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
	EventBus.pickup_spawned.emit("health", global_position)


func _setup_visual() -> void:
	# Remove default green square and white cross
	for child in visual.get_children():
		child.queue_free()

	# Add a proper health pack visual
	var health_visual := _HealthPackVisual.new()
	visual.add_child(health_visual)


class _HealthPackVisual extends Node2D:
	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		# White box with red cross — classic health pack
		# Box
		draw_rect(Rect2(-10, -8, 20, 16), Color(0.95, 0.95, 0.95))
		draw_rect(Rect2(-10, -8, 20, 16), Color(0.6, 0.6, 0.6), false, 1.0)
		# Red cross
		draw_rect(Rect2(-2, -6, 4, 12), Color(0.9, 0.15, 0.15))
		draw_rect(Rect2(-6, -2, 12, 4), Color(0.9, 0.15, 0.15))
		# Shine
		draw_line(Vector2(-8, -6), Vector2(-6, -6), Color(1, 1, 1, 0.5), 1.0)
