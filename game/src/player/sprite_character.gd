## Renders a character using a Kenney Simplified Platformer sprite sheet.
## Replaces stick_figure_visual when real sprites are enabled.
## Frame layout (80x110 per frame, 9 cols x 3 rows):
##   Row 0: Walk cycle (0-8)
##   Row 1: More walk + idle + actions (9-17)
##   Row 2: Jump, fall, misc (18-24)
extends AnimatedSprite2D

const FRAME_W: int = 80
const FRAME_H: int = 110
const COLS: int = 9
const ROWS: int = 3
const ANIM_FPS: float = 10.0

# Frame mapping for each animation
const ANIMS: Dictionary = {
	"idle": [9, 10],                    # standing frames
	"run": [0, 1, 2, 3, 4, 5, 6, 7],   # walk/run cycle
	"jump": [18, 19],                    # jump up
	"fall": [20, 21],                    # falling
	"jetpack": [19, 18],                # reuse jump frames
	"crouch": [16, 17],                  # ducking frames
	"wall_hang": [19],                   # single frame
	"death": [22, 23],                   # hurt/death
}

var parent_player: CharacterBody2D
var _current_anim: String = ""
var _custom_tilesheet: String = ""


func _ready() -> void:
	parent_player = get_parent()

	position = Vector2(0, -20)
	scale = Vector2(0.4, 0.4)

	# Use custom tilesheet if set before _ready, otherwise default
	if _custom_tilesheet != "":
		var tex: Texture2D = load(_custom_tilesheet)
		if tex:
			_build_sprite_frames(tex)
			return
	_build_sprite_frames()


func _process(_delta: float) -> void:
	if not parent_player:
		return

	# Flip based on facing
	flip_h = not parent_player.facing_right

	# Pick animation based on state
	var anim_name: String = _get_anim_name()
	if anim_name != _current_anim:
		_current_anim = anim_name
		if sprite_frames and sprite_frames.has_animation(anim_name):
			play(anim_name)

	# Death fade
	if parent_player.is_dead:
		modulate.a = maxf(modulate.a - _delta * 0.5, 0.2)
	else:
		modulate.a = 1.0


func setup_with_tilesheet(tilesheet_path: String) -> void:
	## Call this BEFORE the node enters the tree (before add_child).
	## The tilesheet is applied in _ready().
	_custom_tilesheet = tilesheet_path


func _build_sprite_frames(custom_texture: Texture2D = null) -> void:
	var texture: Texture2D = custom_texture
	if not texture:
		# Default: player tilesheet
		texture = load("res://assets/sprites/player_tilesheet.png")
	if not texture:
		return

	var frames := SpriteFrames.new()

	# Remove default animation if it exists
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for anim_name in ANIMS:
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, ANIM_FPS)
		frames.set_animation_loop(anim_name, anim_name != "death")

		var frame_indices: Array = ANIMS[anim_name]
		for idx in frame_indices:
			var col: int = idx % COLS
			var row: int = idx / COLS
			var region := Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)

			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			frames.add_frame(anim_name, atlas)

	sprite_frames = frames
	play("idle")


func _get_anim_name() -> String:
	if not parent_player:
		return "idle"

	match parent_player.current_state:
		parent_player.State.IDLE:
			return "idle"
		parent_player.State.RUNNING:
			return "run"
		parent_player.State.JUMPING:
			return "jump"
		parent_player.State.FALLING:
			return "fall"
		parent_player.State.JETPACKING:
			return "jetpack"
		parent_player.State.WALL_HANGING:
			return "wall_hang"
		parent_player.State.CROUCHING:
			return "crouch"
		parent_player.State.DEAD:
			return "death"
	return "idle"
