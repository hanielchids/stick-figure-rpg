## Renders the equipped weapon on the character.
## Uses sprite textures for pistol/shotgun/SMG/sniper.
## Falls back to code-drawn for rocket launcher and knife.
extends Node2D

var player: CharacterBody2D
var _aim_angle: float = 0.0
var _weapon_sprite: Sprite2D

# Preloaded weapon textures
var _weapon_textures: Dictionary = {}

# Scale per weapon to fit the character size
const WEAPON_SCALES: Dictionary = {
	"Pistol": Vector2(0.6, 0.6),
	"Shotgun": Vector2(0.45, 0.45),
	"SMG": Vector2(0.45, 0.45),
	"Sniper": Vector2(0.4, 0.4),
}

const WEAPON_FILES: Dictionary = {
	"Pistol": "res://assets/sprites/weapons/pistol.png",
	"Shotgun": "res://assets/sprites/weapons/shotgun.png",
	"SMG": "res://assets/sprites/weapons/smg.png",
	"Sniper": "res://assets/sprites/weapons/sniper.png",
}

# Code-drawn colors for weapons without sprites
const ROCKET_BODY := Color(0.40, 0.50, 0.40)
const GUN_DARK := Color(0.30, 0.30, 0.35)
const WOOD := Color(0.55, 0.35, 0.20)
const BLADE := Color(0.75, 0.78, 0.82)


func _ready() -> void:
	player = get_parent()
	z_index = 1

	# Create a sprite node for rendering weapon textures
	_weapon_sprite = Sprite2D.new()
	_weapon_sprite.visible = false
	add_child(_weapon_sprite)

	# Preload weapon textures
	for weapon_name in WEAPON_FILES:
		var path: String = WEAPON_FILES[weapon_name]
		var tex: Texture2D = load(path)
		if tex:
			_weapon_textures[weapon_name] = tex


func _process(_delta: float) -> void:
	if not player:
		return

	# Get aim angle
	if player.has_node("InputManager"):
		var im: InputManager = player.get_node("InputManager")
		var center: Vector2 = player.global_position + Vector2(0, -20)
		var aim_vec: Vector2 = im.current_input.aim_position - center
		if aim_vec.length_squared() > 1.0:
			_aim_angle = aim_vec.angle()

	_update_weapon()


func _update_weapon() -> void:
	if not player or player.is_dead:
		_weapon_sprite.visible = false
		queue_redraw()
		return

	if not player.has_node("WeaponManager"):
		return

	var wm: WeaponManager = player.get_node("WeaponManager")
	var weapon: WeaponDefinition = wm.get_current_weapon()
	if not weapon:
		_weapon_sprite.visible = false
		queue_redraw()
		return

	var weapon_name: String = weapon.weapon_name

	if _weapon_textures.has(weapon_name):
		# Use sprite texture
		_weapon_sprite.visible = true
		_weapon_sprite.texture = _weapon_textures[weapon_name]

		# Position at the hand — offset from player center to the side
		var hand_offset: float = 10.0 if player.facing_right else -10.0
		_weapon_sprite.position = Vector2(hand_offset, -22)

		# Rotate to aim angle
		_weapon_sprite.rotation = _aim_angle

		# Scale
		var s: Vector2 = WEAPON_SCALES.get(weapon_name, Vector2(0.5, 0.5))
		_weapon_sprite.scale = s

		# Flip vertically when aiming left so the gun doesn't appear upside down
		if _aim_angle > PI / 2 or _aim_angle < -PI / 2:
			_weapon_sprite.scale.y = -abs(s.y)
		else:
			_weapon_sprite.scale.y = abs(s.y)

		# Offset the sprite so the grip/handle is at the pivot point
		# This makes the gun rotate around the hand, not the center
		_weapon_sprite.offset = Vector2(20, 0)

		queue_redraw()
	else:
		# Code-drawn fallback for rocket launcher and knife
		_weapon_sprite.visible = false
		queue_redraw()


func _draw() -> void:
	if not player or player.is_dead:
		return
	if not player.has_node("WeaponManager"):
		return

	var wm: WeaponManager = player.get_node("WeaponManager")
	var weapon: WeaponDefinition = wm.get_current_weapon()
	if not weapon:
		return

	# Only draw code weapons for types without sprites
	if _weapon_textures.has(weapon.weapon_name):
		return

	var origin: Vector2 = Vector2(0, -24)
	var dir: Vector2 = Vector2.from_angle(_aim_angle)
	var perp: Vector2 = dir.orthogonal()

	match weapon.weapon_name:
		"Rocket Launcher":
			_draw_rocket_launcher(origin, dir, perp)
		"Knife":
			_draw_knife(origin, dir, perp)


func _draw_rocket_launcher(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	var start: Vector2 = origin + dir * 2
	var end: Vector2 = origin + dir * 20
	draw_line(start, end, ROCKET_BODY, 5.0)
	draw_circle(end, 3.5, GUN_DARK)
	draw_circle(end, 2.0, Color(0.2, 0.2, 0.2))
	draw_line(origin + dir * 8, origin + dir * 8 + perp * 5, WOOD, 2.0)
	draw_line(origin + dir * 12 - perp * 3, origin + dir * 14 - perp * 3, Color(0.45, 0.45, 0.50), 1.5)


func _draw_knife(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	var blade_start: Vector2 = origin + dir * 3
	var blade_end: Vector2 = origin + dir * 14
	draw_line(blade_start, blade_end, BLADE, 2.0)
	draw_line(blade_start + perp * 0.5, blade_end + perp * 0.5, Color(0.9, 0.92, 0.95, 0.5), 1.0)
	draw_line(origin, origin + dir * 4, WOOD, 3.0)
	draw_line(origin + dir * 3 - perp * 2, origin + dir * 3 + perp * 2, GUN_DARK, 1.5)
