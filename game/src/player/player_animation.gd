## Manages animation state transitions based on player state.
## Works with the stick figure visual for now, will drive AnimationPlayer
## when real sprite sheets are added.
extends Node

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent()


func _process(_delta: float) -> void:
	if not player:
		return

	# Flip sprite based on facing direction
	var sprite: Sprite2D = player.get_node_or_null("Sprite2D")
	if sprite:
		sprite.flip_h = not player.facing_right

	# Future: drive AnimationPlayer based on player.current_state
	# For now the stick_figure_visual.gd handles visual state changes directly.
	# When real sprites are added, this script will call:
	#   animation_player.play(_get_animation_name())
	#
	# State -> Animation mapping:
	#   IDLE         -> "idle"
	#   RUNNING      -> "run"
	#   JUMPING      -> "jump"
	#   FALLING      -> "fall"
	#   JETPACKING   -> "jetpack"
	#   WALL_HANGING -> "wall_hang"
	#   CROUCHING    -> "crouch"
	#   DEAD         -> "death"


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
