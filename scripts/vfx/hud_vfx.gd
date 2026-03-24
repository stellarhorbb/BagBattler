class_name HudVFX
extends Node

const FONT_BLACK = preload("res://font/LondrinaSolid-Black.ttf")
const ICON_ATK = preload("res://assets/icons/ui/attack-icon.png")
const ICON_DEF = preload("res://assets/icons/ui/defense-icon.png")
const ICON_PSR = preload("res://assets/icons/ui/pressure-icon.png")

var _root: Node

func setup(root: Node) -> void:
	_root = root

func floating_atk(pos: Vector2, value: int) -> void:
	_floating_icon_text(pos, "+%d" % value, ICON_ATK, Color(0.91, 0.16, 0.29, 1))

func floating_def(pos: Vector2, value: int) -> void:
	_floating_icon_text(pos, "+%d" % value, ICON_DEF, Color(0.24, 0.4, 1, 1))

func floating_psr(pos: Vector2, value: float) -> void:
	_floating_icon_text(pos, "+%.2f" % value, ICON_PSR, Color(1, 1, 1, 1))

func _floating_icon_text(pos: Vector2, text: String, icon: Texture2D, icon_modulate: Color, duration: float = 1.4) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.z_index = 100
	_root.add_child(row)
	row.global_position = pos

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(44, 44)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.modulate = icon_modulate
	row.add_child(icon_rect)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", FONT_BLACK)
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(lbl)

	var t = row.create_tween()
	t.set_parallel(true)
	t.tween_property(row, "global_position", pos + Vector2(0, -140), duration).set_ease(Tween.EASE_OUT)
	t.tween_property(row, "modulate:a", 0.0, duration).set_delay(duration * 0.45)
	t.finished.connect(row.queue_free)

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

# Bigger punch — used when PRSR actually multiplies ATK and DEF
func animate_pressure_multiply(label: Label) -> void:
	label.pivot_offset = label.size / 2.0
	var t = label.create_tween()
	t.set_parallel(true)
	t.tween_property(label, "scale", Vector2(2.4, 2.4), 0.10).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(label, "rotation", deg_to_rad(-18.0), 0.10).set_ease(Tween.EASE_OUT)
	await t.finished
	var t2 = label.create_tween()
	t2.set_parallel(true)
	t2.tween_property(label, "scale", Vector2(1.0, 1.0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	t2.tween_property(label, "rotation", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await t2.finished

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

func reset_stat_box(box: PanelContainer) -> void:
	_set_box_color(box, Color(0.1, 0.1, 0.1, 1.0))

func _set_box_color(box: PanelContainer, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_right = 10
	s.corner_radius_bottom_left = 10
	box.add_theme_stylebox_override("panel", s)
