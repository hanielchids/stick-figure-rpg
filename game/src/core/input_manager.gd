## Input abstraction layer. Reads raw input and provides a clean
## PlayerInput struct each frame. Designed for future gamepad / rebinding support.
class_name InputManager
extends Node

## Snapshot of all player inputs for a single frame.
class PlayerInput:
	var move_direction: float = 0.0  # -1 left, 0 none, 1 right
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
	var aim_position: Vector2 = Vector2.ZERO  # world-space mouse position


var current_input: PlayerInput = PlayerInput.new()


func _process(_delta: float) -> void:
	current_input = _read_input()


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

	# Convert screen mouse position to world coordinates
	var canvas: Transform2D = get_viewport().get_canvas_transform()
	input.aim_position = canvas.affine_inverse() * get_viewport().get_mouse_position()

	return input


func get_aim_direction(from_position: Vector2) -> Vector2:
	## Returns normalized direction from a world position toward the mouse.
	return (current_input.aim_position - from_position).normalized()
