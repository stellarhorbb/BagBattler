extends Control

var _time: float = 0.0
var wave_color: Color = Color(0.91, 0.16, 0.29, 1)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var n := 80
	var pts := PackedVector2Array()

	for i in range(n + 1):
		var t := float(i) / n
		var x := t * w
		var y := sin(t * TAU * 2.1 + _time * 1.3) * 22.0 \
			   + sin(t * TAU * 3.8 + _time * 0.85) * 11.0
		pts.append(Vector2(x, y))

	pts.append(Vector2(w, h))
	pts.append(Vector2(0.0, h))
	draw_colored_polygon(pts, wave_color)
