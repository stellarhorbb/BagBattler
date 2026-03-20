extends Control

@onready var compact_view = $CompactView
@onready var modal_view = $ModalView
@onready var modal_content = $ModalView/ModalPanel/ModalContent
@onready var circles_container = $CompactView/CirclesContainer

var bag_manager: BagManager
var _static_tokens: Array[TokenResource] = []

var _font = preload("res://font/LondrinaSolid-Black.ttf")

const TYPE_COLORS = {
	TokenResource.TokenType.ATTACK:   Color("E8294A"),
	TokenResource.TokenType.DEFENSE:  Color("3D4CE8"),
	TokenResource.TokenType.MODIFIER: Color("7B2FE8"),
	TokenResource.TokenType.UTILITY:  Color("FFD700"),
	TokenResource.TokenType.CLEANSER: Color("E0E0E0"),
	TokenResource.TokenType.HAZARD:   Color("2a2a2a"),
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
	_static_tokens = []
	refresh()

func setup_from_array(tokens: Array[TokenResource]) -> void:
	bag_manager = null
	_static_tokens = tokens.duplicate()
	refresh()

func refresh() -> void:
	_build_compact_view()
	if modal_view.visible:
		_build_modal_view()

# --- DATA HELPERS ---

func _get_tokens() -> Array[TokenResource]:
	return bag_manager.bag if bag_manager else _static_tokens

func _get_initial_tokens() -> Array[TokenResource]:
	return bag_manager.initial_bag if bag_manager else _static_tokens

func _get_composition() -> Dictionary:
	if bag_manager:
		return bag_manager.get_bag_composition()
	return _compute_composition(_static_tokens)

func _compute_composition(tokens: Array[TokenResource]) -> Dictionary:
	var composition: Dictionary = {}
	var total_weight := 0.0
	for token in tokens:
		total_weight += token.weight
	for token in tokens:
		var type = token.token_type
		var tname = token.token_name
		if not composition.has(type):
			composition[type] = {}
		if not composition[type].has(tname):
			composition[type][tname] = { "count": 0, "percent": 0.0 }
		var entry = composition[type][tname]
		entry["count"] += 1
		entry["percent"] += (token.weight / total_weight) * 100.0
		composition[type][tname] = entry
	return composition

# --- COMPACT VIEW ---

func _build_compact_view() -> void:
	for child in circles_container.get_children():
		child.free()

	var composition = _get_composition()

	var initial_types: Array[int] = []
	for token in _get_initial_tokens():
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
	label.text = "%d" % _get_tokens().size()
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

	var total = _get_tokens().size()
	var composition = _get_composition()

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
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	circle.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = "×%d" % count
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	circle.add_child(label)
	return circle

func _make_row(token_type: int, token_name: String, count: int, percent: float) -> PanelContainer:
	var outer = PanelContainer.new()
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 1)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	outer.add_theme_stylebox_override("panel", bg_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	outer.add_child(margin)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	# Token name
	var name_label = Label.new()
	name_label.text = token_name.to_upper()
	name_label.add_theme_font_override("font", _font)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.custom_minimum_size = Vector2(240, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	# Spacer pushes count + pile + pct to the right
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	# Count label
	var count_lbl = Label.new()
	count_lbl.text = "x%d" % count
	count_lbl.add_theme_font_override("font", _font)
	count_lbl.add_theme_font_size_override("font_size", 28)
	count_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(count_lbl)

	# Overlapping token pile
	row.add_child(_make_token_pile(token_type, token_name, count))

	# Percentage
	var pct = Label.new()
	pct.text = "%d%%" % roundi(percent)
	pct.add_theme_font_override("font", _font)
	pct.add_theme_font_size_override("font_size", 32)
	pct.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	pct.custom_minimum_size = Vector2(68, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pct)

	return outer

const TOKEN_ICONS = {
	"strike":      "res://assets/icons/tokens/new/strike.png",
	"guard":       "res://assets/icons/tokens/new/guard.png",
	"rampart":     "res://assets/icons/tokens/new/rampart.png",
	"provocation": "res://assets/icons/tokens/new/provocation.png",
	"skull":       "res://assets/icons/tokens/new/skull.png",
	"heal":        "res://assets/icons/tokens/new/heal.png",
	"frenzy":      "res://assets/icons/tokens/frenzy.png",
	"gamble":      "res://assets/icons/tokens/gamble.png",
	"reckless":    "res://assets/icons/tokens/reckless.png",
	"resonance":   "res://assets/icons/tokens/resonance.png",
}

func _make_token_pile(token_type: int, token_name: String, count: int) -> Control:
	const TOKEN_SIZE := 46
	const STEP := 22  # horizontal offset per token (overlap)
	const MAX_VISIBLE := 5
	var n: int = mini(count, MAX_VISIBLE)
	var pile_width: int = TOKEN_SIZE + (n - 1) * STEP

	var pile = Control.new()
	pile.custom_minimum_size = Vector2(pile_width, TOKEN_SIZE)

	for i in n:
		var token = _make_mini_token(token_type, token_name)
		token.position = Vector2(i * STEP, 0)
		token.z_index = i
		pile.add_child(token)

	return pile

func _make_mini_token(token_type: int, token_name: String) -> Control:
	const TOKEN_SIZE := 46
	const ICON_SIZE := 26
	var container = Control.new()
	container.custom_minimum_size = Vector2(TOKEN_SIZE, TOKEN_SIZE)

	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(token_type, Color(0.3, 0.3, 0.3, 1))
	style.corner_radius_top_left = TOKEN_SIZE / 2
	style.corner_radius_top_right = TOKEN_SIZE / 2
	style.corner_radius_bottom_left = TOKEN_SIZE / 2
	style.corner_radius_bottom_right = TOKEN_SIZE / 2
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color.WHITE
	bg.add_theme_stylebox_override("panel", style)
	container.add_child(bg)

	var icon_key = token_name.to_lower()
	if TOKEN_ICONS.has(icon_key) and ResourceLoader.exists(TOKEN_ICONS[icon_key]):
		var icon = TextureRect.new()
		icon.texture = load(TOKEN_ICONS[icon_key])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		var half := ICON_SIZE / 2
		var center := TOKEN_SIZE / 2
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = center - half
		icon.offset_top = center - half
		icon.offset_right = -(center - half)
		icon.offset_bottom = -(center - half)
		container.add_child(icon)

	return container
