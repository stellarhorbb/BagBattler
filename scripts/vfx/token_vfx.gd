class_name TokenVFX
extends Node

var _root: Node

func setup(root: Node) -> void:
	_root = root

# Card tilt + ring pulse — used during token resolution
func play_resolution(card: Control, color: Color) -> void:
	_tilt_card(card)
	_ring_pulse(card, color)

# Quick hard tilt — used for ATK/DEF/enemy intention strike moments
func tilt_hard(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var t = node.create_tween()
	t.set_parallel(true)
	t.tween_property(node, "scale", Vector2(1.7, 1.7), 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(node, "rotation", deg_to_rad(14.0), 0.08)
	await t.finished
	var t2 = node.create_tween()
	t2.set_parallel(true)
	t2.tween_property(node, "scale", Vector2(1.0, 1.0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	t2.tween_property(node, "rotation", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await t2.finished

func _tilt_card(card: Control) -> void:
	card.pivot_offset = card.size / 2.0
	var tw = card.create_tween()
	tw.tween_property(card, "rotation_degrees", -18.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "rotation_degrees", 0.0, 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)

func _ring_pulse(card: Control, color: Color) -> void:
	var ring := Panel.new()
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0, 0, 0, 0)
	ring_style.border_width_left = 5
	ring_style.border_width_top = 5
	ring_style.border_width_right = 5
	ring_style.border_width_bottom = 5
	ring_style.border_color = color
	ring_style.corner_radius_top_left = 70
	ring_style.corner_radius_top_right = 70
	ring_style.corner_radius_bottom_right = 70
	ring_style.corner_radius_bottom_left = 70
	ring.add_theme_stylebox_override("panel", ring_style)
	ring.size = card.size
	ring.pivot_offset = card.size / 2.0
	ring.global_position = card.global_position
	ring.z_index = 100
	ring.z_as_relative = false
	_root.add_child(ring)
	var rt = ring.create_tween()
	rt.set_parallel(true)
	rt.tween_property(ring, "scale", Vector2(2.2, 2.2), 1.5).set_ease(Tween.EASE_OUT)
	rt.tween_property(ring, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN)
	rt.finished.connect(ring.queue_free)
