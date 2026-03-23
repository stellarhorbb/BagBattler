class_name HudVFX
extends Node

const FONT_BLACK = preload("res://font/LondrinaSolid-Black.ttf")

var _root: Node

func setup(root: Node) -> void:
	_root = root

# Floating number/text that rises and fades from a world position
func floating_text(pos: Vector2, text: String, color: Color, duration: float = 1.4) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", FONT_BLACK)
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.add_theme_color_override("font_color", color)
	_root.add_child(lbl)
	lbl.global_position = pos
	lbl.z_index = 100
	var t = lbl.create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "global_position", pos + Vector2(0, -140), duration).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, duration).set_delay(duration * 0.45)
	t.finished.connect(lbl.queue_free)

# Pressure label bounce — used when pressure increments
func animate_pressure_label(label: Label) -> void:
	label.pivot_offset = label.size / 2.0
	var t = label.create_tween()
	t.set_parallel(true)
	t.tween_property(label, "scale", Vector2(1.7, 1.7), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(label, "rotation", deg_to_rad(14.0), 0.12).set_ease(Tween.EASE_OUT)
	await t.finished
	var t2 = label.create_tween()
	t2.set_parallel(true)
	t2.tween_property(label, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	t2.tween_property(label, "rotation", 0.0, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await t2.finished

# ATK/DEF stat label tilt + color flash — used during pressure resolution
func animate_pressure_on_stat(label: RichTextLabel, new_text: String, box: PanelContainer, color: Color) -> void:
	label.parse_bbcode("[center][color=#ffffff]%s[/color][/center]" % new_text)
	_set_box_color(box, color)
	label.pivot_offset = label.size / 2.0
	var tilt := deg_to_rad(8.0) if color.r > 0.5 else deg_to_rad(-8.0)
	var t = label.create_tween()
	t.set_parallel(true)
	t.tween_property(label, "scale", Vector2(1.35, 1.35), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(label, "rotation", tilt, 0.1).set_ease(Tween.EASE_OUT)
	await t.finished
	var t2 = label.create_tween()
	t2.set_parallel(true)
	t2.tween_property(label, "scale", Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	t2.tween_property(label, "rotation", 0.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await t2.finished

func _set_box_color(box: PanelContainer, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_right = 10
	s.corner_radius_bottom_left = 10
	box.add_theme_stylebox_override("panel", s)
