## Map 3: Bunker — Tight corridors and rooms. Close-quarters combat.
extends Node2D

const MAP_W: float = 1400.0
const MAP_H: float = 800.0

var _platform_data: Array = []


func _ready() -> void:
	_build_background()
	_build_walls()
	_build_platforms()
	_build_kill_zone()
	_build_spawn_points()
	_build_navigation()
	_build_decorations()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(MAP_W, MAP_H)
	bg.color = Color(0.08, 0.09, 0.14)
	bg.z_index = -10
	add_child(bg)


func _build_walls() -> void:
	_add_collider(Vector2(MAP_W / 2, MAP_H - 16), Vector2(MAP_W, 32))
	TileDecorator.decorate_ground(self, Vector2(MAP_W / 2, MAP_H - 16), Vector2(MAP_W, 32), "stone")
	_add_collider(Vector2(16, MAP_H / 2), Vector2(32, MAP_H))
	TileDecorator.decorate_wall(self, Vector2(16, MAP_H / 2), Vector2(32, MAP_H))
	_add_collider(Vector2(MAP_W - 16, MAP_H / 2), Vector2(32, MAP_H))
	TileDecorator.decorate_wall(self, Vector2(MAP_W - 16, MAP_H / 2), Vector2(32, MAP_H))
	_add_collider(Vector2(MAP_W / 2, 16), Vector2(MAP_W, 32))
	TileDecorator.decorate_ground(self, Vector2(MAP_W / 2, 16), Vector2(MAP_W, 32), "stone")


func _build_platforms() -> void:
	# Inner walls creating rooms
	_add_pillar(Vector2(400, MAP_H - 150), Vector2(20, 250))
	_add_pillar(Vector2(MAP_W - 400, MAP_H - 150), Vector2(20, 250))

	# Center room ceiling
	_add_platform_ground(Vector2(MAP_W / 2, MAP_H - 350), Vector2(500, 20))

	# Floor platforms inside rooms
	_add_platform(Vector2(200, MAP_H - 100), Vector2(140, 14))
	_add_platform(Vector2(MAP_W - 200, MAP_H - 100), Vector2(140, 14))
	_add_platform(Vector2(MAP_W / 2, MAP_H - 120), Vector2(120, 14))

	# Upper level platforms
	_add_platform(Vector2(200, MAP_H - 400), Vector2(160, 14))
	_add_platform(Vector2(MAP_W - 200, MAP_H - 400), Vector2(160, 14))
	_add_platform(Vector2(MAP_W / 2, MAP_H - 500), Vector2(180, 14))

	# Connecting bridges
	_add_platform(Vector2(MAP_W / 2 - 150, MAP_H - 220), Vector2(100, 12))
	_add_platform(Vector2(MAP_W / 2 + 150, MAP_H - 220), Vector2(100, 12))

	# Cover crates
	_add_pillar(Vector2(300, MAP_H - 50), Vector2(40, 40))
	_add_pillar(Vector2(MAP_W - 300, MAP_H - 50), Vector2(40, 40))
	_add_pillar(Vector2(MAP_W / 2, MAP_H - 50), Vector2(50, 50))


func _add_collider(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = Constants.LAYER_WORLD
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _add_platform(pos: Vector2, size: Vector2) -> void:
	_platform_data.append([pos, size])
	_add_collider(pos, size)
	TileDecorator.decorate_platform(self, pos, size)


func _add_platform_ground(pos: Vector2, size: Vector2) -> void:
	_platform_data.append([pos, size])
	_add_collider(pos, size)
	TileDecorator.decorate_ground(self, pos, size, "stone")


func _add_pillar(pos: Vector2, size: Vector2) -> void:
	_platform_data.append([pos, size])
	_add_collider(pos, size)
	TileDecorator.decorate_wall(self, pos, size)


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


func _build_decorations() -> void:
	var floor_y: float = MAP_H - 32
	TileDecorator.add_decoration(self, Vector2(150, floor_y - 5), TileDecorator.CRATE)
	TileDecorator.add_decoration(self, Vector2(MAP_W - 150, floor_y - 5), TileDecorator.CRATE)
	TileDecorator.add_decoration(self, Vector2(MAP_W / 2, floor_y - 10), TileDecorator.SIGN)
	TileDecorator.add_decoration(self, Vector2(500, floor_y - 5), TileDecorator.ROCK_SMALL)
	TileDecorator.add_decoration(self, Vector2(MAP_W - 500, floor_y - 5), TileDecorator.ROCK_SMALL)
