## Polished stick figure character visual.
## Draws a detailed stick figure with head features, weapon in hand,
## animated legs, and state-specific poses.
## Ready to be swapped for real sprites via AnimationPlayer later.
extends Sprite2D

@export var body_color: Color = Color(0.9, 0.9, 0.9)
@export var accent_color: Color = Color(0.4, 0.7, 1.0)  # belt, headband
@export var weapon_color: Color = Color(0.6, 0.6, 0.6)
@export var eye_color: Color = Color(0.1, 0.1, 0.1)

var parent_player: CharacterBody2D
var _walk_cycle: float = 0.0  # animates legs
var _damage_flash: float = 0.0  # red flash on hit
var _death_timer: float = 0.0


func _ready() -> void:
	parent_player = get_parent()
	texture = null

	# Connect to damage signal if available
	if parent_player and parent_player.has_node("HealthSystem"):
		var hs: Node = parent_player.get_node("HealthSystem")
		if hs.has_signal("damage_taken"):
			hs.damage_taken.connect(_on_damage_taken)


func _process(delta: float) -> void:
	if not parent_player:
		return

	# Animate walk cycle
	if parent_player.current_state == parent_player.State.RUNNING:
		_walk_cycle += delta * 12.0
	elif parent_player.current_state == parent_player.State.IDLE:
		_walk_cycle = lerpf(_walk_cycle, 0.0, delta * 5.0)

	# Damage flash decay
	if _damage_flash > 0:
		_damage_flash = maxf(_damage_flash - delta * 4.0, 0.0)

	# Death animation
	if parent_player.is_dead:
		_death_timer += delta

	queue_redraw()


func _draw() -> void:
	var lw: float = 2.5  # line width — thicker for polished look
	var aim_angle: float = 0.0
	var state: int = 0
	var facing: bool = true

	if parent_player:
		state = parent_player.current_state
		facing = parent_player.facing_right
		if parent_player.has_node("InputManager"):
			var im: InputManager = parent_player.get_node("InputManager")
			var center_mass: Vector2 = parent_player.global_position + Vector2(0, -20)
			var aim_vec: Vector2 = im.current_input.aim_position - center_mass
			if aim_vec.length_squared() > 1.0:
				aim_angle = aim_vec.angle()

	# Apply damage flash tint
	var draw_color: Color = body_color
	if _damage_flash > 0:
		draw_color = body_color.lerp(Color(1.0, 0.2, 0.2), _damage_flash)

	if parent_player and parent_player.is_dead:
		_draw_dead(lw, draw_color)
		return

	match state:
		0, 1:  # IDLE, RUNNING
			_draw_character(lw, aim_angle, facing, draw_color, false, false)
		2, 3:  # JUMPING, FALLING
			_draw_character(lw, aim_angle, facing, draw_color, false, true)
		4:  # JETPACKING
			_draw_character(lw, aim_angle, facing, draw_color, true, true)
		5:  # WALL_HANGING
			_draw_wall_hang(lw, aim_angle, facing, draw_color)
		6:  # CROUCHING
			_draw_crouched(lw, aim_angle, facing, draw_color)


func _draw_character(lw: float, aim_angle: float, facing: bool, color: Color, jetpacking: bool, airborne: bool) -> void:
	var dir: float = 1.0 if facing else -1.0

	# === HEAD ===
	var head_center := Vector2(0, -14)
	# Head circle (slightly oval)
	draw_circle(head_center, 7.0, color)
	# Eye
	var eye_pos := head_center + Vector2(dir * 3, -1)
	draw_circle(eye_pos, 1.5, eye_color)
	# Eye shine
	draw_circle(eye_pos + Vector2(0.5, -0.5), 0.5, Color.WHITE)
	# Headband
	draw_line(head_center + Vector2(-6, -3), head_center + Vector2(6, -3), accent_color, 2.0)
	# Headband tail (flutters)
	if not facing:
		var flutter: float = sin(Time.get_ticks_msec() * 0.008) * 2.0
		draw_line(head_center + Vector2(6, -3), head_center + Vector2(10, -1 + flutter), accent_color, 1.5)
	else:
		var flutter: float = sin(Time.get_ticks_msec() * 0.008) * 2.0
		draw_line(head_center + Vector2(-6, -3), head_center + Vector2(-10, -1 + flutter), accent_color, 1.5)

	# === BODY ===
	var neck := Vector2(0, -7)
	var hip := Vector2(0, 5)
	draw_line(neck, hip, color, lw + 1)  # thicker body
	# Belt
	draw_line(Vector2(-4, 3), Vector2(4, 3), accent_color, 2.0)

	# === ARMS ===
	var shoulder := Vector2(0, -5)
	# Front arm — holds weapon, points at aim
	var arm_end: Vector2 = shoulder + Vector2.from_angle(aim_angle) * 12.0
	var elbow: Vector2 = shoulder + Vector2.from_angle(aim_angle) * 6.0
	draw_line(shoulder, elbow, color, lw)
	draw_line(elbow, arm_end, color, lw)
	# Hand circle
	draw_circle(arm_end, 1.5, color)

	# Back arm — relaxed or bracing
	var back_arm_angle: float = aim_angle + 0.4 * dir
	var back_end: Vector2 = shoulder + Vector2.from_angle(back_arm_angle) * 9.0
	draw_line(shoulder, back_end, color, lw * 0.8)

	# === WEAPON ===
	_draw_weapon(arm_end, aim_angle, facing)

	# === LEGS ===
	if airborne:
		if jetpacking:
			# Legs dangling, slightly spread
			draw_line(hip, hip + Vector2(-4, 13), color, lw)
			draw_line(hip, hip + Vector2(4, 14), color, lw)
			# Feet
			draw_line(hip + Vector2(-4, 13), hip + Vector2(-1, 14), color, lw)
			draw_line(hip + Vector2(4, 14), hip + Vector2(7, 15), color, lw)
		else:
			# Tucked legs in air
			var tuck: float = 0.3 if parent_player.velocity.y < 0 else -0.2
			draw_line(hip, hip + Vector2(-5, 10 + tuck * 5), color, lw)
			draw_line(hip, hip + Vector2(5, 10 - tuck * 5), color, lw)
	else:
		# Walking animation
		var leg_swing: float = sin(_walk_cycle) * 5.0
		# Front leg
		var knee_f := hip + Vector2(leg_swing, 7)
		var foot_f := knee_f + Vector2(leg_swing * 0.5, 6)
		draw_line(hip, knee_f, color, lw)
		draw_line(knee_f, foot_f, color, lw)
		# Back leg
		var knee_b := hip + Vector2(-leg_swing, 7)
		var foot_b := knee_b + Vector2(-leg_swing * 0.5, 6)
		draw_line(hip, knee_b, color, lw)
		draw_line(knee_b, foot_b, color, lw)
		# Feet (small horizontal lines)
		draw_line(foot_f, foot_f + Vector2(dir * 3, 0), color, lw)
		draw_line(foot_b, foot_b + Vector2(dir * 3, 0), color, lw)

	# === JETPACK ===
	if jetpacking:
		_draw_jetpack_flame()


func _draw_weapon(hand_pos: Vector2, aim_angle: float, _facing: bool) -> void:
	if not parent_player or not parent_player.has_node("WeaponManager"):
		return

	var wm: WeaponManager = parent_player.get_node("WeaponManager")
	var weapon: WeaponDefinition = wm.get_current_weapon()
	if not weapon:
		return

	var gun_dir: Vector2 = Vector2.from_angle(aim_angle)

	match weapon.weapon_name:
		"Pistol":
			draw_line(hand_pos, hand_pos + gun_dir * 6, weapon_color, 2.5)
		"Shotgun":
			draw_line(hand_pos, hand_pos + gun_dir * 10, weapon_color, 3.0)
			draw_line(hand_pos + gun_dir * 8, hand_pos + gun_dir * 10 + gun_dir.orthogonal() * 2, weapon_color, 2.0)
		"SMG":
			draw_line(hand_pos, hand_pos + gun_dir * 8, weapon_color, 2.0)
			# Magazine
			draw_line(hand_pos + gun_dir * 4, hand_pos + gun_dir * 4 + Vector2(0, 3), weapon_color, 1.5)
		"Sniper":
			draw_line(hand_pos, hand_pos + gun_dir * 14, weapon_color, 2.0)
			# Scope
			draw_circle(hand_pos + gun_dir * 10, 1.5, weapon_color)
		"Rocket Launcher":
			draw_line(hand_pos, hand_pos + gun_dir * 12, weapon_color, 3.5)
			# Opening
			draw_circle(hand_pos + gun_dir * 12, 2.5, Color(0.3, 0.3, 0.3))
		"Knife":
			draw_line(hand_pos, hand_pos + gun_dir * 7, Color(0.8, 0.8, 0.8), 1.5)
			# Handle
			draw_line(hand_pos, hand_pos - gun_dir * 2, Color(0.5, 0.3, 0.1), 2.5)


func _draw_jetpack_flame() -> void:
	var flame_base := Vector2(-3, 2)
	var time: float = Time.get_ticks_msec() * 0.01
	var flicker1: float = sin(time) * 3.0
	var flicker2: float = cos(time * 1.3) * 2.5
	var flicker3: float = sin(time * 0.7) * 2.0

	# Jetpack body on back
	draw_rect(Rect2(-6, -4, 4, 10), Color(0.35, 0.35, 0.4))

	# Main flame
	var flame_color := Color(1.0, 0.5, 0.1, 0.9)
	var inner_color := Color(1.0, 0.8, 0.2, 0.8)
	var tip_color := Color(1.0, 0.3, 0.0, 0.6)

	# Outer flame
	draw_line(flame_base, flame_base + Vector2(flicker1, 14 + abs(flicker2)), flame_color, 4.0)
	# Inner flame (brighter)
	draw_line(flame_base, flame_base + Vector2(flicker2 * 0.5, 10 + abs(flicker1)), inner_color, 2.5)
	# Tip
	draw_line(flame_base + Vector2(0, 10), flame_base + Vector2(flicker3, 18 + abs(flicker1)), tip_color, 1.5)

	# Second nozzle
	var flame_base2 := Vector2(-5, 2)
	draw_line(flame_base2, flame_base2 + Vector2(flicker2 * 0.7, 10 + abs(flicker3)), flame_color, 3.0)


func _draw_crouched(lw: float, aim_angle: float, facing: bool, color: Color) -> void:
	var dir: float = 1.0 if facing else -1.0

	# Head (lower)
	var head_center := Vector2(dir * 3, -4)
	draw_circle(head_center, 6.0, color)
	# Eye
	draw_circle(head_center + Vector2(dir * 3, -1), 1.5, eye_color)
	draw_circle(head_center + Vector2(dir * 3 + 0.5, -1.5), 0.5, Color.WHITE)
	# Headband
	draw_line(head_center + Vector2(-5, -2), head_center + Vector2(5, -2), accent_color, 2.0)

	# Body (hunched forward)
	var neck := head_center + Vector2(0, 5)
	var hip := Vector2(dir * -2, 8)
	draw_line(neck, hip, color, lw + 1)
	# Belt
	draw_line(hip + Vector2(-3, 0), hip + Vector2(3, 0), accent_color, 2.0)

	# Arms — aim
	var shoulder := (neck + hip) * 0.5
	var arm_end: Vector2 = shoulder + Vector2.from_angle(aim_angle) * 10.0
	draw_line(shoulder, arm_end, color, lw)
	draw_circle(arm_end, 1.5, color)
	_draw_weapon(arm_end, aim_angle, facing)

	# Legs (bent knees)
	var knee_l := hip + Vector2(-6, 4)
	var foot_l := knee_l + Vector2(-3, 4)
	var knee_r := hip + Vector2(6, 4)
	var foot_r := knee_r + Vector2(3, 4)
	draw_line(hip, knee_l, color, lw)
	draw_line(knee_l, foot_l, color, lw)
	draw_line(hip, knee_r, color, lw)
	draw_line(knee_r, foot_r, color, lw)
	draw_line(foot_l, foot_l + Vector2(dir * 3, 0), color, lw)
	draw_line(foot_r, foot_r + Vector2(dir * 3, 0), color, lw)


func _draw_wall_hang(lw: float, aim_angle: float, facing: bool, color: Color) -> void:
	var dir: float = 1.0 if facing else -1.0

	# Head
	var head_center := Vector2(dir * -2, -14)
	draw_circle(head_center, 6.0, color)
	draw_circle(head_center + Vector2(dir * 3, -1), 1.5, eye_color)
	draw_line(head_center + Vector2(-5, -2), head_center + Vector2(5, -2), accent_color, 2.0)

	# Body pressed against wall
	var neck := Vector2(dir * -2, -8)
	var hip := Vector2(dir * -2, 5)
	draw_line(neck, hip, color, lw + 1)

	# Arms — one gripping wall, one aiming
	# Wall grip arm
	draw_line(neck + Vector2(0, 2), Vector2(dir * -8, -10), color, lw)
	# Aim arm
	var arm_end: Vector2 = neck + Vector2(0, 2) + Vector2.from_angle(aim_angle) * 10.0
	draw_line(neck + Vector2(0, 2), arm_end, color, lw)
	_draw_weapon(arm_end, aim_angle, facing)

	# Legs — one bent against wall, one dangling
	draw_line(hip, hip + Vector2(dir * -4, 6), color, lw)
	draw_line(hip + Vector2(dir * -4, 6), hip + Vector2(dir * -6, 10), color, lw)
	draw_line(hip, hip + Vector2(2, 10), color, lw)


func _draw_dead(lw: float, color: Color) -> void:
	# Fallen on the ground — flat
	var fade: float = clampf(1.0 - _death_timer * 0.5, 0.2, 1.0)
	var dead_color: Color = Color(color.r, color.g, color.b, fade)

	var ground_y: float = 5.0
	# Body flat on ground
	draw_line(Vector2(-12, ground_y), Vector2(12, ground_y), dead_color, lw + 1)
	# Head
	draw_circle(Vector2(-14, ground_y - 2), 5.0, dead_color)
	# X eyes
	draw_line(Vector2(-16, ground_y - 4), Vector2(-12, ground_y), Color(0.8, 0.2, 0.2, fade), 1.5)
	draw_line(Vector2(-12, ground_y - 4), Vector2(-16, ground_y), Color(0.8, 0.2, 0.2, fade), 1.5)
	# Arms splayed
	draw_line(Vector2(-6, ground_y), Vector2(-8, ground_y - 6), dead_color, lw)
	draw_line(Vector2(4, ground_y), Vector2(6, ground_y - 5), dead_color, lw)
	# Legs
	draw_line(Vector2(8, ground_y), Vector2(10, ground_y + 4), dead_color, lw)
	draw_line(Vector2(12, ground_y), Vector2(14, ground_y - 3), dead_color, lw)


func _on_damage_taken(_amount: float, _from_id: int) -> void:
	_damage_flash = 1.0
