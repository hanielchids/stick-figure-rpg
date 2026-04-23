## Map 1: Arena — Multi-level combat arena.
## Collision via StaticBody2D, visuals via Kenney Pixel Platformer tiles.
extends Node2D

const MAP_W: float = 1600.0
const MAP_H: float = 900.0

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
	bg.color = Color(0.12, 0.15, 0.22)
	bg.z_index = -10
	add_child(bg)


func _build_walls() -> void:
	# Floor
	_add_collider(Vector2(MAP_W / 2, MAP_H - 16), Vector2(MAP_W, 32))
	TileDecorator.decorate_ground(self, Vector2(MAP_W / 2, MAP_H - 16), Vector2(MAP_W, 32), "grass")

	# Left wall
	_add_collider(Vector2(16, MAP_H / 2), Vector2(32, MAP_H))
	TileDecorator.decorate_wall(self, Vector2(16, MAP_H / 2), Vector2(32, MAP_H))

	# Right wall
	_add_collider(Vector2(MAP_W - 16, MAP_H / 2), Vector2(32, MAP_H))
	TileDecorator.decorate_wall(self, Vector2(MAP_W - 16, MAP_H / 2), Vector2(32, MAP_H))

	# Ceiling
	_add_collider(Vector2(MAP_W / 2, 16), Vector2(MAP_W, 32))
	TileDecorator.decorate_ground(self, Vector2(MAP_W / 2, 16), Vector2(MAP_W, 32), "stone")


func _build_platforms() -> void:
	# Ground level small platforms
	_add_platform(Vector2(400, 788), Vector2(120, 16))
	_add_platform(Vector2(1200, 788), Vector2(120, 16))

	# Mid-level platforms
	_add_platform(Vector2(250, 618), Vector2(180, 16))
	_add_platform(Vector2(800, 588), Vector2(200, 16))
	_add_platform(Vector2(1350, 618), Vector2(180, 16))

	# High platforms
	_add_platform(Vector2(500, 418), Vector2(160, 16))
	_add_platform(Vector2(1100, 418), Vector2(160, 16))

	# Top center platform
	_add_platform(Vector2(800, 268), Vector2(140, 16))

	# Cover pillars
	_add_pillar(Vector2(600, 728), Vector2(16, 100))
	_add_pillar(Vector2(1000, 728), Vector2(16, 100))


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
	area.body_entered.connect(_on_kill_zone_entered)
	add_child(area)


func _on_kill_zone_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_node("HealthSystem"):
		var health: HealthSystem = body.get_node("HealthSystem")
		health.take_damage(9999.0, -1, "Fell")


func _build_spawn_points() -> void:
	var positions: Array[Vector2] = [
		Vector2(200, 820), Vector2(1400, 820),
		Vector2(500, 820), Vector2(1100, 820),
		Vector2(300, 820), Vector2(700, 820),
		Vector2(900, 820), Vector2(1200, 820),
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
	# Plants on the ground (just above floor surface)
	var floor_y: float = MAP_H - 32
	TileDecorator.add_decoration(self, Vector2(150, floor_y - 5), TileDecorator.PLANT_1)
	TileDecorator.add_decoration(self, Vector2(350, floor_y - 5), TileDecorator.MUSHROOM)
	TileDecorator.add_decoration(self, Vector2(700, floor_y - 5), TileDecorator.PLANT_2)
	TileDecorator.add_decoration(self, Vector2(950, floor_y - 5), TileDecorator.PLANT_1)
	TileDecorator.add_decoration(self, Vector2(1300, floor_y - 5), TileDecorator.MUSHROOM)
	TileDecorator.add_decoration(self, Vector2(1500, floor_y - 5), TileDecorator.PLANT_2)

	# Signs near spawn areas
	TileDecorator.add_decoration(self, Vector2(200, floor_y - 10), TileDecorator.SIGN)
	TileDecorator.add_decoration(self, Vector2(1400, floor_y - 10), TileDecorator.SIGN)

	# Crates near pillars
	TileDecorator.add_decoration(self, Vector2(580, floor_y - 5), TileDecorator.CRATE)
	TileDecorator.add_decoration(self, Vector2(1020, floor_y - 5), TileDecorator.CRATE)

	# Small rocks on platforms
	TileDecorator.add_decoration(self, Vector2(270, 600), TileDecorator.ROCK_SMALL)
	TileDecorator.add_decoration(self, Vector2(1330, 600), TileDecorator.ROCK_SMALL)
