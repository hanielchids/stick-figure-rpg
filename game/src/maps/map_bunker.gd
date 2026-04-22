## Map 3: Bunker — Tight corridors and rooms. Close-quarters combat.
extends Node2D

const MAP_W: float = 1400.0
const MAP_H: float = 800.0

const C_BG := Color(0.07, 0.08, 0.11)
const C_FLOOR := Color(0.30, 0.28, 0.25)
const C_WALL := Color(0.26, 0.24, 0.22)
const C_CEIL := Color(0.22, 0.20, 0.18)
const C_INNER := Color(0.28, 0.26, 0.24)
const C_PLAT := Color(0.34, 0.32, 0.28)

var _platform_data: Array = []


func _ready() -> void:
	_build_background()
	_build_walls()
	_build_platforms()
	_build_kill_zone()
	_build_spawn_points()
	_build_navigation()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(MAP_W, MAP_H)
	bg.color = C_BG
	bg.z_index = -10
	add_child(bg)


func _build_walls() -> void:
	_add_rect(Vector2(MAP_W / 2, MAP_H - 16), Vector2(MAP_W, 32), C_FLOOR)
	_add_rect(Vector2(16, MAP_H / 2), Vector2(32, MAP_H), C_WALL)
	_add_rect(Vector2(MAP_W - 16, MAP_H / 2), Vector2(32, MAP_H), C_WALL)
	_add_rect(Vector2(MAP_W / 2, 16), Vector2(MAP_W, 32), C_CEIL)


func _build_platforms() -> void:
	# Inner walls creating rooms
	# Left room divider (with gap at top for jetpack access)
	_add_platform(Vector2(400, MAP_H - 150), Vector2(20, 250), C_INNER)

	# Right room divider
	_add_platform(Vector2(MAP_W - 400, MAP_H - 150), Vector2(20, 250), C_INNER)

	# Center room ceiling (creates a bunker room in the middle)
	_add_platform(Vector2(MAP_W / 2, MAP_H - 350), Vector2(500, 20), C_INNER)

	# Floor platforms inside rooms
	_add_platform(Vector2(200, MAP_H - 100), Vector2(140, 14), C_PLAT)
	_add_platform(Vector2(MAP_W - 200, MAP_H - 100), Vector2(140, 14), C_PLAT)
	_add_platform(Vector2(MAP_W / 2, MAP_H - 120), Vector2(120, 14), C_PLAT)

	# Upper level platforms
	_add_platform(Vector2(200, MAP_H - 400), Vector2(160, 14), C_PLAT)
	_add_platform(Vector2(MAP_W - 200, MAP_H - 400), Vector2(160, 14), C_PLAT)
	_add_platform(Vector2(MAP_W / 2, MAP_H - 500), Vector2(180, 14), C_PLAT)

	# Connecting bridges
	_add_platform(Vector2(MAP_W / 2 - 150, MAP_H - 220), Vector2(100, 12), C_PLAT)
	_add_platform(Vector2(MAP_W / 2 + 150, MAP_H - 220), Vector2(100, 12), C_PLAT)

	# Cover crates
	_add_platform(Vector2(300, MAP_H - 50), Vector2(40, 40), C_INNER)
	_add_platform(Vector2(MAP_W - 300, MAP_H - 50), Vector2(40, 40), C_INNER)
	_add_platform(Vector2(MAP_W / 2, MAP_H - 50), Vector2(50, 50), C_INNER)


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


func _add_platform(pos: Vector2, size: Vector2, color: Color) -> void:
	_platform_data.append([pos, size])
	_add_rect(pos, size, color)


func _build_kill_zone() -> void:
	var area := Area2D.new()
	area.position = Vector2(MAP_W / 2, MAP_H + 50)
	area.collision_layer = Constants.LAYER_KILLZONE
	area.collision_mask = Constants.LAYER_PLAYERS
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(MAP_W, 60)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body is CharacterBody2D and body.has_node("HealthSystem"):
			var health: HealthSystem = body.get_node("HealthSystem")
			health.take_damage(9999.0, -1, "Fell")
	)
	add_child(area)


func _build_spawn_points() -> void:
	var positions: Array[Vector2] = [
		Vector2(100, MAP_H - 50), Vector2(MAP_W - 100, MAP_H - 50),
		Vector2(MAP_W / 2, MAP_H - 50), Vector2(200, MAP_H - 50),
		Vector2(MAP_W - 200, MAP_H - 50), Vector2(MAP_W / 2 - 100, MAP_H - 50),
		Vector2(MAP_W / 2 + 100, MAP_H - 50), Vector2(350, MAP_H - 50),
	]
	for i in positions.size():
		var marker := Marker2D.new()
		marker.name = "PlayerSpawn%d" % i
		marker.position = positions[i]
		add_child(marker)


func _build_navigation() -> void:
	var nav_region := NavigationRegion2D.new()
	add_child(nav_region)
	var nav_poly := NavigationPolygon.new()
	var margin: float = 40.0
	nav_poly.add_outline(PackedVector2Array([
		Vector2(margin, margin), Vector2(MAP_W - margin, margin),
		Vector2(MAP_W - margin, MAP_H - margin), Vector2(margin, MAP_H - margin),
	]))
	for plat in _platform_data:
		var center: Vector2 = plat[0]
		var size: Vector2 = plat[1]
		var half: Vector2 = size / 2.0
		nav_poly.add_outline(PackedVector2Array([
			center + Vector2(-half.x, -half.y), center + Vector2(-half.x, half.y),
			center + Vector2(half.x, half.y), center + Vector2(half.x, -half.y),
		]))
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
