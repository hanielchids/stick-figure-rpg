## Input abstraction layer. Reads raw input and provides a clean
## PlayerInput struct each frame. Supports keyboard+mouse and touchscreen.
class_name InputManager
extends Node

## Snapshot of all player inputs for a single frame.
class PlayerInput:
	var move_direction: float = 0.0
	var jump_pressed: bool = false
	var jump_held: bool = false
	var crouch_held: bool = false
	var jetpack_held: bool = false
	var fire_pressed: bool = false
	var fire_held: bool = false
	var reload_pressed: bool = false
	var swap_weapon_pressed: bool = false
	var interact_pressed: bool = false
	var scoreboard_held: bool = false
	var aim_position: Vector2 = Vector2.ZERO


var current_input: PlayerInput = PlayerInput.new()
var _is_mobile: bool = false
var _touch_aim_position: Vector2 = Vector2.ZERO
var _touch_aim_active: bool = false


func _ready() -> void:
	_is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


func _process(_delta: float) -> void:
	current_input = _read_input()


func _input(event: InputEvent) -> void:
	if not _is_mobile:
		return

	# On mobile, tapping/dragging the right side of the screen controls aim
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		var screen_width: float = get_viewport().get_visible_rect().size.x
		if touch.position.x > screen_width * 0.4:
			if touch.pressed:
				_touch_aim_active = true
				var canvas: Transform2D = get_viewport().get_canvas_transform()
				_touch_aim_position = canvas.affine_inverse() * touch.position
			else:
				_touch_aim_active = false

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		var screen_width: float = get_viewport().get_visible_rect().size.x
		if drag.position.x > screen_width * 0.4:
			_touch_aim_active = true
			var canvas: Transform2D = get_viewport().get_canvas_transform()
			_touch_aim_position = canvas.affine_inverse() * drag.position


func _read_input() -> PlayerInput:
	var input := PlayerInput.new()

	input.move_direction = Input.get_axis("move_left", "move_right")
	input.jump_pressed = Input.is_action_just_pressed("jump")
	input.jump_held = Input.is_action_pressed("jump")
	input.crouch_held = Input.is_action_pressed("crouch")
	input.jetpack_held = Input.is_action_pressed("jetpack")
	input.fire_pressed = Input.is_action_just_pressed("fire")
	input.fire_held = Input.is_action_pressed("fire")
	input.reload_pressed = Input.is_action_just_pressed("reload")
	input.swap_weapon_pressed = Input.is_action_just_pressed("swap_weapon")
	input.interact_pressed = Input.is_action_just_pressed("interact")
	input.scoreboard_held = Input.is_action_pressed("scoreboard")

	# Aim position — mouse on desktop, touch on mobile
	if _is_mobile and _touch_aim_active:
		input.aim_position = _touch_aim_position
	else:
		var canvas: Transform2D = get_viewport().get_canvas_transform()
		input.aim_position = canvas.affine_inverse() * get_viewport().get_mouse_position()

	return input


func get_aim_direction(from_position: Vector2) -> Vector2:
	return (current_input.aim_position - from_position).normalized()
