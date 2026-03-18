extends Control

var _active: bool = false
var _color: Color = Color.WHITE
var _time: float = 0.0

func set_ring(active: bool, color: Color = Color.WHITE) -> void:
	_active = active
	_color = color
	if not active:
		queue_redraw()

func _process(delta: float) -> void:
	if _active:
		_time += delta
		queue_redraw()

func _draw() -> void:
	if not _active:
		return

	var cx := 85.0
	var cy := 85.0
	var base_r := 83.0
	var amplitude := 3.5
	var n_waves := 6
	var n_pts := 80

	var pts := PackedVector2Array()
	for i in range(n_pts + 1):
		var angle := float(i) / n_pts * TAU
		var r := base_r + amplitude * sin(n_waves * angle + _time * 3.5)
		pts.append(Vector2(cx + r * cos(angle), cy + r * sin(angle)))

	draw_polyline(pts, _color, 4.0, true)
