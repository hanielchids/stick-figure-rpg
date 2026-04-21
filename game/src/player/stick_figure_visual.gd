## Draws a simple stick figure as placeholder art.
## Attach to the Sprite2D node on the player.
extends Sprite2D

@export var body_color: Color = Color(0.9, 0.9, 0.9)
@export var head_radius: float = 6.0
@export var body_height: float = 16.0
@export var limb_length: float = 10.0

var parent_player: CharacterBody2D


func _ready() -> void:
	parent_player = get_parent()
	texture = null


func _draw() -> void:
	var line_width := 2.0
	var is_crouching := false
	var is_jetpacking := false
	var aim_angle := 0.4

	if parent_player:
		is_crouching = parent_player.current_state == parent_player.State.CROUCHING
		is_jetpacking = parent_player.current_state == parent_player.State.JETPACKING
		if parent_player.has_node("InputManager"):
			var im: InputManager = parent_player.get_node("InputManager")
			# Aim from center mass (player origin + sprite offset)
			var center_mass: Vector2 = parent_player.global_position + Vector2(0, -20)
			var aim_vec: Vector2 = im.current_input.aim_position - center_mass
			if aim_vec.length_squared() > 1.0:
				aim_angle = aim_vec.angle()

	if is_crouching:
		_draw_crouching(line_width, aim_angle)
	elif is_jetpacking:
		_draw_jetpacking(line_width, aim_angle)
	else:
		_draw_standing(line_width, aim_angle)


func _draw_standing(line_width: float, aim_angle: float) -> void:
	# Head
	draw_circle(Vector2(0, -body_height * 0.5 - head_radius), head_radius, body_color)

	# Body
	draw_line(
		Vector2(0, -body_height * 0.5),
		Vector2(0, body_height * 0.5),
		body_color, line_width
	)

	# Arms — point toward aim
	var arm_origin := Vector2(0, -body_height * 0.2)
	draw_line(arm_origin, arm_origin + Vector2.from_angle(aim_angle) * limb_length, body_color, line_width)
	draw_line(arm_origin, arm_origin + Vector2.from_angle(aim_angle + 0.3) * limb_length * 0.8, body_color, line_width)

	# Legs
	var leg_origin := Vector2(0, body_height * 0.5)
	draw_line(leg_origin, leg_origin + Vector2(-5, limb_length), body_color, line_width)
	draw_line(leg_origin, leg_origin + Vector2(5, limb_length), body_color, line_width)


func _draw_crouching(line_width: float, aim_angle: float) -> void:
	var crouch_offset := 8.0  # squish everything down

	# Head (lower)
	draw_circle(Vector2(0, -body_height * 0.2 - head_radius + crouch_offset), head_radius, body_color)

	# Body (shorter, angled forward)
	var body_top := Vector2(0, -body_height * 0.2 + crouch_offset)
	var body_bottom := Vector2(3, body_height * 0.3 + crouch_offset)
	draw_line(body_top, body_bottom, body_color, line_width)

	# Arms — still aim
	var arm_origin := (body_top + body_bottom) * 0.5
	draw_line(arm_origin, arm_origin + Vector2.from_angle(aim_angle) * limb_length * 0.8, body_color, line_width)
	draw_line(arm_origin, arm_origin + Vector2.from_angle(aim_angle + 0.3) * limb_length * 0.6, body_color, line_width)

	# Legs (bent, knees out)
	var leg_origin := body_bottom
	var knee_left := leg_origin + Vector2(-8, 4)
	var foot_left := knee_left + Vector2(-2, 6)
	var knee_right := leg_origin + Vector2(8, 4)
	var foot_right := knee_right + Vector2(2, 6)
	draw_line(leg_origin, knee_left, body_color, line_width)
	draw_line(knee_left, foot_left, body_color, line_width)
	draw_line(leg_origin, knee_right, body_color, line_width)
	draw_line(knee_right, foot_right, body_color, line_width)


func _draw_jetpacking(line_width: float, aim_angle: float) -> void:
	# Head
	draw_circle(Vector2(0, -body_height * 0.5 - head_radius), head_radius, body_color)

	# Body
	draw_line(
		Vector2(0, -body_height * 0.5),
		Vector2(0, body_height * 0.5),
		body_color, line_width
	)

	# Arms — point toward aim
	var arm_origin := Vector2(0, -body_height * 0.2)
	draw_line(arm_origin, arm_origin + Vector2.from_angle(aim_angle) * limb_length, body_color, line_width)
	draw_line(arm_origin, arm_origin + Vector2.from_angle(aim_angle + 0.3) * limb_length * 0.8, body_color, line_width)

	# Legs (dangling down and back)
	var leg_origin := Vector2(0, body_height * 0.5)
	draw_line(leg_origin, leg_origin + Vector2(-3, limb_length + 2), body_color, line_width)
	draw_line(leg_origin, leg_origin + Vector2(3, limb_length + 4), body_color, line_width)

	# Jetpack flame (flickering)
	var flame_color := Color(1.0, 0.5, 0.1, 0.9)
	var flame_base := Vector2(0, body_height * 0.5 + 2)
	var time := fmod(Time.get_ticks_msec() / 50.0, 6.28)
	var flicker := sin(time) * 3.0
	draw_line(flame_base, flame_base + Vector2(flicker, 12 + abs(flicker)), flame_color, 3.0)
	draw_line(flame_base, flame_base + Vector2(-flicker * 0.7, 10 + abs(flicker) * 0.5), Color(1.0, 0.8, 0.2, 0.7), 2.0)


func _process(_delta: float) -> void:
	queue_redraw()
