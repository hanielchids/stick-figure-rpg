## Draws a simple crosshair. Attach to the Crosshair TextureRect in HUD.
extends TextureRect


func _ready() -> void:
	texture = null
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center: Vector2 = size / 2
	var gap: float = 3.0
	var length: float = 7.0
	var color: Color = Color(0.0, 1.0, 0.0, 0.9)
	var width: float = 1.5

	# Four lines forming a cross with a gap in the middle
	draw_line(center + Vector2(0, -gap), center + Vector2(0, -gap - length), color, width)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), color, width)
	draw_line(center + Vector2(-gap, 0), center + Vector2(-gap - length, 0), color, width)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), color, width)

	# Center dot
	draw_circle(center, 1.0, color)
