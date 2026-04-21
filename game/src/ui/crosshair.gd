## Custom crosshair that replaces the OS mouse cursor.
## Hides system cursor and draws a crosshair at the exact mouse position.
extends Control


func _ready() -> void:
	# Hide OS cursor during gameplay — crosshair replaces it
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Make this control fill the entire screen
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = get_local_mouse_position()
	var gap: float = 4.0
	var length: float = 8.0
	var color: Color = Color(0.0, 1.0, 0.0, 0.9)
	var width: float = 2.0

	# Four lines forming a cross with a gap in the middle
	draw_line(center + Vector2(0, -gap), center + Vector2(0, -gap - length), color, width)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), color, width)
	draw_line(center + Vector2(-gap, 0), center + Vector2(-gap - length, 0), color, width)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), color, width)

	# Center dot
	draw_circle(center, 1.5, color)
