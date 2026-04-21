## Map 1: Arena — Multi-level combat arena built with ColorRects.
## Upgrade to TileMap during polish phase.
extends Node2D


func _ready() -> void:
	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(1600, 900)
	bg.color = Color(0.10, 0.11, 0.15)
	bg.z_index = -10
	add_child(bg)

	# Walls and floor
	_add_rect(Vector2(800, 884), Vector2(1600, 32), Color(0.28, 0.32, 0.38))   # floor
	_add_rect(Vector2(16, 450), Vector2(32, 900), Color(0.24, 0.28, 0.34))      # left wall
	_add_rect(Vector2(1584, 450), Vector2(32, 900), Color(0.24, 0.28, 0.34))    # right wall
	_add_rect(Vector2(800, 16), Vector2(1600, 32), Color(0.22, 0.25, 0.30))     # ceiling

	# Ground-level small platforms
	_add_rect(Vector2(400, 788), Vector2(120, 16), Color(0.34, 0.38, 0.44))
	_add_rect(Vector2(1200, 788), Vector2(120, 16), Color(0.34, 0.38, 0.44))

	# Mid-level platforms
	_add_rect(Vector2(250, 618), Vector2(180, 16), Color(0.32, 0.36, 0.42))
	_add_rect(Vector2(800, 588), Vector2(200, 16), Color(0.32, 0.36, 0.42))
	_add_rect(Vector2(1350, 618), Vector2(180, 16), Color(0.32, 0.36, 0.42))

	# High platforms
	_add_rect(Vector2(500, 418), Vector2(160, 16), Color(0.30, 0.34, 0.40))
	_add_rect(Vector2(1100, 418), Vector2(160, 16), Color(0.30, 0.34, 0.40))

	# Top center platform
	_add_rect(Vector2(800, 268), Vector2(140, 16), Color(0.28, 0.32, 0.38))

	# Cover pillars
	_add_rect(Vector2(600, 728), Vector2(16, 100), Color(0.26, 0.30, 0.36))
	_add_rect(Vector2(1000, 728), Vector2(16, 100), Color(0.26, 0.30, 0.36))

	# Kill zone below floor
	_add_kill_zone(Vector2(800, 950), Vector2(1600, 60))


func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = Constants.LAYER_WORLD

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	visual.color = color
	body.add_child(visual)

	add_child(body)


func _add_kill_zone(pos: Vector2, size: Vector2) -> void:
	var area := Area2D.new()
	area.position = pos
	area.collision_layer = Constants.LAYER_KILLZONE
	area.collision_mask = Constants.LAYER_PLAYERS

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	area.add_child(shape)

	area.body_entered.connect(_on_kill_zone_entered)
	add_child(area)


func _on_kill_zone_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_node("HealthSystem"):
		var health: HealthSystem = body.get_node("HealthSystem")
		health.take_damage(9999.0, -1, "Fell")
