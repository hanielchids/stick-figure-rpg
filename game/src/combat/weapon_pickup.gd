## A weapon pickup in the world. Players walk over it to swap their current weapon.
## Respawns after a timer.
extends Area2D

@export var weapon_resource: WeaponDefinition
@export var respawn_time: float = Constants.WEAPON_PICKUP_RESPAWN

var is_available: bool = true
var _respawn_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


const WEAPON_SPRITES: Dictionary = {
	"Pistol": "res://assets/sprites/weapons/pistol.png",
	"Shotgun": "res://assets/sprites/weapons/shotgun.png",
	"SMG": "res://assets/sprites/weapons/smg.png",
	"Sniper": "res://assets/sprites/weapons/sniper.png",
}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = Constants.LAYER_PICKUPS
	collision_mask = Constants.LAYER_PLAYERS

	# Replace blue rectangle with actual weapon sprite
	_setup_visual()

	# Float animation
	var tween := create_tween().set_loops()
	tween.tween_property(visual, "position:y", -4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual, "position:y", 4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _setup_visual() -> void:
	if not weapon_resource:
		return

	# Remove the default blue rectangle
	var icon: Node = visual.get_node_or_null("Icon")
	if icon:
		icon.queue_free()

	# Add weapon sprite
	var weapon_name: String = weapon_resource.weapon_name
	if WEAPON_SPRITES.has(weapon_name):
		var sprite := Sprite2D.new()
		sprite.texture = load(WEAPON_SPRITES[weapon_name])
		sprite.scale = Vector2(0.6, 0.6)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.add_child(sprite)
	else:
		# Code-drawn fallback for weapons without sprites (rocket, knife)
		var drawn := _WeaponPickupVisual.new()
		drawn.weapon_name = weapon_name
		visual.add_child(drawn)

	# Update the label with weapon name
	var label: Node = visual.get_node_or_null("Label")
	if label and label is Label:
		label.text = weapon_name
		label.add_theme_font_size_override("font_size", 10)


class _WeaponPickupVisual extends Node2D:
	var weapon_name: String = ""

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		match weapon_name:
			"Rocket Launcher":
				draw_line(Vector2(-10, 0), Vector2(10, 0), Color(0.4, 0.5, 0.4), 5.0)
				draw_circle(Vector2(10, 0), 3.0, Color(0.3, 0.3, 0.3))
				draw_circle(Vector2(-10, 0), 2.0, Color(0.8, 0.3, 0.1))
			"Knife":
				draw_line(Vector2(-6, 0), Vector2(6, 0), Color(0.75, 0.78, 0.82), 2.0)
				draw_line(Vector2(-6, 0), Vector2(-10, 0), Color(0.55, 0.35, 0.2), 3.0)


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
	EventBus.pickup_spawned.emit("weapon", global_position)
