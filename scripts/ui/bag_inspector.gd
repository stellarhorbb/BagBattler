extends Control

@onready var compact_view = $CompactView
@onready var modal_view = $ModalView
@onready var modal_content = $ModalView/ModalPanel/ModalContent
@onready var circles_container = $CompactView/CirclesContainer

var bag_manager: BagManager

var _font = preload("res://font/LondrinaSolid-Black.ttf")

const TYPE_COLORS = {
	TokenResource.TokenType.ATTACK:   Color("E8294A"),
	TokenResource.TokenType.DEFENSE:  Color("3D4CE8"),
	TokenResource.TokenType.MODIFIER: Color("7B2FE8"),
	TokenResource.TokenType.UTILITY:  Color("FFD700"),
	TokenResource.TokenType.CLEANSER: Color("E0E0E0"),
	TokenResource.TokenType.HAZARD:   Color("2a2a2a"),
}

const TYPE_ICONS = {
	TokenResource.TokenType.ATTACK:   "res://assets/icons/ui/attack-bag-inspector.png",
	TokenResource.TokenType.DEFENSE:  "res://assets/icons/ui/defense-bag-inspector.png",
	TokenResource.TokenType.MODIFIER: "res://assets/icons/ui/modifier-bag-inspector.png",
	TokenResource.TokenType.HAZARD:   "res://assets/icons/ui/skull-bag-inspector-grey.png",
}

const TYPE_ORDER = [
	TokenResource.TokenType.ATTACK,
	TokenResource.TokenType.DEFENSE,
	TokenResource.TokenType.MODIFIER,
	TokenResource.TokenType.UTILITY,
	TokenResource.TokenType.CLEANSER,
	TokenResource.TokenType.HAZARD,
]

func setup(bm: BagManager) -> void:
	bag_manager = bm
	refresh()

func refresh() -> void:
	_build_compact_view()
	if modal_view.visible:
		_build_modal_view()

# --- COMPACT VIEW ---

func _build_compact_view() -> void:
	for child in circles_container.get_children():
		child.free()

	var composition = bag_manager.get_bag_composition()

	var initial_types: Array[int] = []
	for token in bag_manager.initial_bag:
		var t = int(token.token_type)
		if not initial_types.has(t):
			initial_types.append(t)

	for token_type in TYPE_ORDER:
		if not initial_types.has(int(token_type)):
			continue

		var total_count = 0
		if composition.has(token_type):
			for token_name in composition[token_type]:
				total_count += composition[token_type][token_name]["count"]

		var circle = _make_circle(token_type, total_count)
		circles_container.add_child(circle)

	var label = Label.new()
	label.text = "%d" % bag_manager.bag.size()
	label.add_theme_font_size_override("font_size", 24)
	circles_container.add_child(label)

	call_deferred("_sync_compact_size")

func _sync_compact_size() -> void:
	var content_size = circles_container.get_combined_minimum_size()
	var new_w = content_size.x + 16.0
	var new_h = max(content_size.y + 8.0, 60.0)
	compact_view.set_offset(SIDE_LEFT, -new_w / 2.0)
	compact_view.set_offset(SIDE_RIGHT,  new_w / 2.0)
	var v_center = (compact_view.get_offset(SIDE_TOP) + compact_view.get_offset(SIDE_BOTTOM)) / 2.0
	compact_view.set_offset(SIDE_TOP,    v_center - new_h / 2.0)
	compact_view.set_offset(SIDE_BOTTOM, v_center + new_h / 2.0)

# --- MODAL ---

func _build_modal_view() -> void:
	for child in modal_content.get_children():
		child.free()

	var total = bag_manager.bag.size()
	var composition = bag_manager.get_bag_composition()

	# Title
	var title = Label.new()
	title.text = "COMPOSITION"
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "%d LEFT" % total
	subtitle.add_theme_font_override("font", _font)
	subtitle.add_theme_font_size_override("font_size", 29)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 21)
	modal_content.add_child(spacer)

	# Rows per token name
	for token_type in TYPE_ORDER:
		if not composition.has(token_type):
			continue
		for token_name in composition[token_type]:
			var data = composition[token_type][token_name]
			modal_content.add_child(_make_row(token_type, token_name, data["count"], data["percent"]))

# --- OPEN / CLOSE ---

func open_modal() -> void:
	if modal_view.visible:
		return
	_build_modal_view()
	modal_view.visible = true
	var t = create_tween()
	t.tween_property(modal_view, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func close_modal() -> void:
	if not modal_view.visible:
		return
	var t = create_tween()
	t.tween_property(modal_view, "modulate:a", 0.0, 0.14).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func(): modal_view.visible = false)

# --- HELPERS ---

func _make_circle(token_type: int, count: int) -> Control:
	var circle = Panel.new()
	circle.custom_minimum_size = Vector2(60, 60)
	var style = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(token_type, Color.WHITE)
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	circle.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = "×%d" % count
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	circle.add_child(label)
	return circle

func _make_row(token_type: int, token_name: String, count: int, percent: float) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	# Token name
	var name_label = Label.new()
	name_label.text = token_name.to_upper()
	name_label.add_theme_font_override("font", _font)
	name_label.add_theme_font_size_override("font_size", 34)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.custom_minimum_size = Vector2(260, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	# Icons right after the name (one per token count)
	var dots = HBoxContainer.new()
	dots.add_theme_constant_override("separation", 4)
	if TYPE_ICONS.has(token_type):
		for i in count:
			dots.add_child(_make_icon(token_type))
	row.add_child(dots)

	# Spacer pushes percentage to the right
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	# Percentage
	var pct = Label.new()
	pct.text = "%d%%" % roundi(percent)
	pct.add_theme_font_override("font", _font)
	pct.add_theme_font_size_override("font_size", 34)
	pct.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	pct.custom_minimum_size = Vector2(78, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pct)

	return row

func _make_icon(token_type: int) -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = load(TYPE_ICONS[token_type])
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon
