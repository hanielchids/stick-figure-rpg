## On-screen touch controls for mobile (Android/iOS).
## Shows virtual joystick for movement, buttons for jump/jetpack/fire/reload/swap.
## Only visible on touchscreen devices.
extends CanvasLayer

var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_touch_index: int = -1
var _joystick_input: Vector2 = Vector2.ZERO
var _is_mobile: bool = false

# Joystick config
const JOYSTICK_RADIUS: float = 60.0
const JOYSTICK_DEAD_ZONE: float = 10.0

# Button references
@onready var joystick_bg: Control = $JoystickBG
@onready var joystick_knob: Control = $JoystickBG/Knob
@onready var fire_button: TouchScreenButton = $FireButton
@onready var jump_button: TouchScreenButton = $JumpButton
@onready var jetpack_button: TouchScreenButton = $JetpackButton
@onready var reload_button: TouchScreenButton = $ReloadButton
@onready var swap_button: TouchScreenButton = $SwapButton


func _ready() -> void:
	# Only show on mobile
	_is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

	if not _is_mobile:
		visible = false
		set_process(false)
		set_process_input(false)
		return

	layer = 5
	_joystick_center = joystick_bg.position + Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)


func _input(event: InputEvent) -> void:
	if not _is_mobile:
		return

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			# Check if touch is in joystick area (left side of screen)
			if touch.position.x < get_viewport().get_visible_rect().size.x * 0.4:
				if touch.position.distance_to(_joystick_center) < JOYSTICK_RADIUS * 2:
					_joystick_touch_index = touch.index
		else:
			if touch.index == _joystick_touch_index:
				_joystick_touch_index = -1
				_joystick_input = Vector2.ZERO
				joystick_knob.position = Vector2.ZERO

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == _joystick_touch_index:
			var offset: Vector2 = drag.position - _joystick_center
			if offset.length() > JOYSTICK_RADIUS:
				offset = offset.normalized() * JOYSTICK_RADIUS
			_joystick_input = offset / JOYSTICK_RADIUS

			# Move knob visual
			joystick_knob.position = offset


func _process(_delta: float) -> void:
	if not _is_mobile:
		return

	# Apply joystick input to the input system
	if absf(_joystick_input.x) > JOYSTICK_DEAD_ZONE / JOYSTICK_RADIUS:
		Input.action_press("move_right" if _joystick_input.x > 0 else "move_left", absf(_joystick_input.x))
		Input.action_release("move_left" if _joystick_input.x > 0 else "move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
