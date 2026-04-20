## Smooth follow camera with aim look-ahead and screen shake.
## Attach to a Camera2D node as a child of the player.
extends Camera2D

## How far ahead the camera looks in the aim direction.
@export var look_ahead_distance: float = 60.0
## How fast the camera smooths to the target offset.
@export var look_ahead_smooth: float = 5.0
## How fast the camera follows the player position.
@export var follow_smooth: float = 8.0

var _target_offset: Vector2 = Vector2.ZERO
var _current_offset: Vector2 = Vector2.ZERO
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0

@onready var player: CharacterBody2D = get_parent()


func _ready() -> void:
	# Enable smoothing on the camera itself
	position_smoothing_enabled = false  # We handle smoothing manually
	make_current()


func _process(delta: float) -> void:
	_update_look_ahead(delta)
	_update_shake(delta)

	offset = _current_offset + _get_shake_offset()


func _update_look_ahead(delta: float) -> void:
	if not player or not player.has_node("InputManager"):
		return

	var im: InputManager = player.get_node("InputManager")
	var aim_dir := (im.current_input.aim_position - player.global_position).normalized()

	_target_offset = aim_dir * look_ahead_distance
	_current_offset = _current_offset.lerp(_target_offset, look_ahead_smooth * delta)


func _update_shake(delta: float) -> void:
	_shake_intensity = maxf(_shake_intensity - _shake_decay * delta, 0.0)


func _get_shake_offset() -> Vector2:
	if _shake_intensity <= 0.0:
		return Vector2.ZERO
	return Vector2(
		randf_range(-_shake_intensity, _shake_intensity),
		randf_range(-_shake_intensity, _shake_intensity)
	)


func shake(intensity: float = 5.0, decay: float = 5.0) -> void:
	## Triggers screen shake. Call from combat system on hits, explosions, etc.
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_decay = decay


func set_map_bounds(bounds: Rect2) -> void:
	## Clamp camera to map edges. Call when loading a map.
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)
