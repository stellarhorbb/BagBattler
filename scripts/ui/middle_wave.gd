extends Control

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var n := 100
	var pts := PackedVector2Array()

	# Top wavy edge — left to right
	for i in range(n + 1):
		var t := float(i) / n
		var x := t * w
		var y := sin(t * TAU * 2.1 + _time * 1.3) * 22.0 \
			   + sin(t * TAU * 3.8 + _time * 0.85) * 11.0
		pts.append(Vector2(x, y))

	# Bottom wavy edge — right to left
	for i in range(n + 1):
		var t := float(n - i) / n
		var x := t * w
		var y := h + sin(t * TAU * 2.5 + _time * 1.1 + 1.5) * 22.0 \
				   + sin(t * TAU * 3.3 + _time * 0.7 + 0.9) * 11.0
		pts.append(Vector2(x, y))

	draw_colored_polygon(pts, Color.WHITE)
