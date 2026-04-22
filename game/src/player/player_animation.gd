## Manages animation state transitions based on player state.
## Currently drives stick_figure_visual.gd (code-drawn).
## When real sprite sheets are added:
##   1. Add an AnimatedSprite2D or AnimationPlayer to the player scene
##   2. Set use_sprite_sheet = true
##   3. This script will call play() on the AnimatedSprite2D
##   4. The stick_figure_visual can be hidden/removed
extends Node

## Set to true when real sprite sheets are added to switch from code-drawn to sprites.
@export var use_sprite_sheet: bool = false

var player: CharacterBody2D
var _current_anim: String = ""


func _ready() -> void:
	player = get_parent()


func _process(_delta: float) -> void:
	if not player:
		return

	var anim_name: String = _get_animation_name()

	if use_sprite_sheet:
		# Drive AnimatedSprite2D or AnimationPlayer
		var animated_sprite: Node = player.get_node_or_null("AnimatedSprite2D")
		if animated_sprite and animated_sprite.has_method("play"):
			if anim_name != _current_anim:
				animated_sprite.call("play", anim_name)
				_current_anim = anim_name
			animated_sprite.flip_h = not player.facing_right

		# Hide stick figure when using real sprites
		var stick_fig: Node = player.get_node_or_null("Sprite2D")
		if stick_fig:
			stick_fig.visible = false
	else:
		# Stick figure handles its own drawing — just flip
		var sprite: Sprite2D = player.get_node_or_null("Sprite2D")
		if sprite:
			sprite.flip_h = not player.facing_right


func _get_animation_name() -> String:
	match player.current_state:
		player.State.IDLE:
			return "idle"
		player.State.RUNNING:
			return "run"
		player.State.JUMPING:
			return "jump"
		player.State.FALLING:
			return "fall"
		player.State.JETPACKING:
			return "jetpack"
		player.State.WALL_HANGING:
			return "wall_hang"
		player.State.CROUCHING:
			return "crouch"
		player.State.DEAD:
			return "death"
	return "idle"
