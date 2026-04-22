## Manages animation state transitions.
## SpriteCharacter (AnimatedSprite2D) handles its own animation when present.
## This script is kept for backward compatibility and flip logic on the stick figure fallback.
extends Node

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent()


func _process(_delta: float) -> void:
	if not player:
		return

	# Flip stick figure fallback if visible
	var stick_fig: Sprite2D = player.get_node_or_null("Sprite2D")
	if stick_fig and stick_fig.visible:
		stick_fig.flip_h = not player.facing_right
