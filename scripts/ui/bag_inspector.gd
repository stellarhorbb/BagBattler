extends Control

@onready var compact_view = $CompactView
@onready var modal_view = $ModalView
@onready var modal_content = $ModalView/ModalPanel/ModalContent
@onready var circles_container = $CompactView/CirclesContainer

var bag_manager: BagManager
var _static_tokens: Array[TokenResource] = []
var _opened_by_tab: bool = false

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

func _ready() -> void:
	$CompactView.pressed.connect(toggle_modal)
	$ModalView/Dimmer.gui_input.connect(_on_dimmer_input)

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

	var panels_row := HBoxContainer.new()
	panels_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panels_row.add_theme_constant_override("separation", 24)
	modal_content.add_child(panels_row)

	# Left: Run Stats (only in live run)
	var left_panel := _build_run_stats_panel()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.3
	panels_row.add_child(left_panel)

	# Vertical divider
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(2, 0)
	divider.color = Color(1, 1, 1, 0.12)
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panels_row.add_child(divider)

	# Right: Bag Composition
	var right_panel := _build_composition_panel()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 0.7
	panels_row.add_child(right_panel)

func _build_run_stats_panel() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	# Title row: "RUN STATS" left, HP% right
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 0)
	title_row.add_child(title_vbox)

	var title := Label.new()
	title.text = "RUN STATS"
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color.WHITE)
	title_vbox.add_child(title)

	if GameManager.selected_job != null:
		var ante := GameManager.get_current_ante()
		var zone_in_ante := GameManager.get_zone_in_ante()
		var depth := GameManager.get_depth_name().to_upper()
		var subtitle := Label.new()
		subtitle.text = "%d.%d %s" % [ante, zone_in_ante, depth]
		subtitle.add_theme_font_override("font", _font)
		subtitle.add_theme_font_size_override("font_size", 20)
		subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		title_vbox.add_child(subtitle)

	if GameManager.selected_job != null:
		var hp_pct := roundi(GameManager.player_current_hp * 100.0 / max(GameManager.player_max_hp, 1))
		var hp_label := Label.new()
		hp_label.text = "%d%%" % hp_pct
		hp_label.add_theme_font_override("font", _font)
		hp_label.add_theme_font_size_override("font_size", 42)
		hp_label.add_theme_color_override("font_color", Color.WHITE)
		hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_row.add_child(hp_label)

	# Class row
	if GameManager.selected_job != null:
		var class_row := _make_list_row("CLASS", GameManager.selected_job.job_name.to_upper())
		vbox.add_child(class_row)

	# Stat boxes: ATK DEF HP PRSR
	if GameManager.selected_job != null:
		var stats_row := HBoxContainer.new()
		stats_row.add_theme_constant_override("separation", 8)
		vbox.add_child(stats_row)

		var atk_bonus := GameManager.base_damage - GameManager.selected_job.base_damage
		var def_bonus := GameManager.base_defense - GameManager.selected_job.base_defense
		var hp_bonus := GameManager.player_max_hp - GameManager.selected_job.base_hp
		var prsr_bonus := GameManager.base_pressure_floor - 1.0

		stats_row.add_child(_make_stat_box("ATK", "+%d" % atk_bonus, Color("E8294A"), true))
		stats_row.add_child(_make_stat_box("DEF", "+%d" % def_bonus, Color("3D4CE8"), true))
		stats_row.add_child(_make_stat_box("HP", "+%d" % hp_bonus, Color(0.18, 0.18, 0.18, 1), false))
		stats_row.add_child(_make_stat_box("PRSR", "+%.2f" % prsr_bonus, Color(0.18, 0.18, 0.18, 1), false))

	# Token added / sacrificed boxes
	if GameManager.selected_job != null:
		var token_row := HBoxContainer.new()
		token_row.add_theme_constant_override("separation", 8)
		vbox.add_child(token_row)

		var added := GameManager.purchased_tokens.size()
		var sacrificed := GameManager.sacrificed_tokens.size()
		token_row.add_child(_make_count_box("TOKEN ADDED", str(added)))
		token_row.add_child(_make_count_box("TOKEN SACRIFICED", str(sacrificed)))

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	# List rows
	if GameManager.selected_job != null:
		var moon_count := GameManager.purchased_moon_phases.size()
		var shells_count := GameManager.shells_opened
		var salt_total := GameManager.total_salt_earned
		var crashes := GameManager.total_crashes

		vbox.add_child(_make_list_row("MOON CARDS CONSUMED", "x%d" % moon_count))
		vbox.add_child(_make_list_row("SHELLS CONSUMED", "x%d" % shells_count))
		vbox.add_child(_make_list_row("TOTAL SALT EARNED", "x%d" % salt_total))
		vbox.add_child(_make_list_row("TOTAL CRASHES", "x%d" % crashes))

	return vbox

func _build_composition_panel() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)

	var total := _get_tokens().size()
	var composition := _get_composition()

	# Title row
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 0)
	title_row.add_child(title_vbox)

	var title := Label.new()
	title.text = "BAG COMPOSITION"
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color.WHITE)
	title_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "TOKENS LEFT"
	subtitle.add_theme_font_override("font", _font)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	title_vbox.add_child(subtitle)

	var count_label := Label.new()
	count_label.text = "x%d" % total
	count_label.add_theme_font_override("font", _font)
	count_label.add_theme_font_size_override("font_size", 42)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(count_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(spacer)

	# Scrollable token rows
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var rows_vbox := VBoxContainer.new()
	rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_vbox.add_theme_constant_override("separation", 13)
	scroll.add_child(rows_vbox)

	for token_type in TYPE_ORDER:
		if not composition.has(token_type):
			continue
		for token_name in composition[token_type]:
			var data = composition[token_type][token_name]
			var res := _find_token_resource(token_name)
			rows_vbox.add_child(_make_row(token_type, token_name, data["count"], data["percent"], res))

	return vbox

# --- TOGGLE ---

func toggle_modal() -> void:
	_opened_by_tab = false
	if modal_view.visible:
		_close_modal()
	else:
		_open_modal()

func open_by_tab() -> void:
	if not modal_view.visible:
		_opened_by_tab = true
		_open_modal()

func close_by_tab() -> void:
	if _opened_by_tab:
		_opened_by_tab = false
		_close_modal()

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_opened_by_tab = false
		_close_modal()

func _open_modal() -> void:
	_build_modal_view()
	modal_view.visible = true
	var t = create_tween()
	t.tween_property(modal_view, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _close_modal() -> void:
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

func _make_stat_box(stat_name: String, value: String, bg_color: Color, colored: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	margin.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = stat_name
	name_lbl.add_theme_font_override("font", _font)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_override("font", _font)
	val_lbl.add_theme_font_size_override("font_size", 34)
	val_lbl.add_theme_color_override("font_color", Color.WHITE)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val_lbl)

	return panel

func _make_count_box(label_text: String, value: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	margin.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_override("font", _font)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_override("font", _font)
	val_lbl.add_theme_font_size_override("font_size", 40)
	val_lbl.add_theme_color_override("font_color", Color.WHITE)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val_lbl)

	return panel

func _make_list_row(label_text: String, value: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	margin.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_font_override("font", _font)
	val.add_theme_font_size_override("font_size", 22)
	val.add_theme_color_override("font_color", Color.WHITE)
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(val)

	return panel

func _find_token_resource(token_name: String) -> TokenResource:
	for token in _get_tokens():
		if token.token_name == token_name:
			return token
	return null

func _make_row(token_type: int, token_name: String, count: int, percent: float, res: TokenResource = null) -> PanelContainer:
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
	name_label.custom_minimum_size = Vector2(180, 0)
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
	row.add_child(_make_token_pile(token_type, token_name, count, res))

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
	"swing":       "res://assets/icons/tokens/new/swing.png",
	"frenzy":      "res://assets/icons/tokens/frenzy.png",
	"gamble":      "res://assets/icons/tokens/gamble.png",
	"reckless":    "res://assets/icons/tokens/reckless.png",
	"resonance":   "res://assets/icons/tokens/resonance.png",
}

func _make_token_pile(token_type: int, token_name: String, count: int, res: TokenResource = null) -> Control:
	const TOKEN_SIZE := 46
	const STEP := 22  # horizontal offset per token (overlap)
	const MAX_VISIBLE := 5
	var n: int = mini(count, MAX_VISIBLE)
	var pile_width: int = TOKEN_SIZE + (n - 1) * STEP

	var pile = Control.new()
	pile.custom_minimum_size = Vector2(pile_width, TOKEN_SIZE)

	for i in n:
		var token = _make_mini_token(token_type, token_name, res)
		token.position = Vector2(i * STEP, 0)
		token.z_index = i
		pile.add_child(token)

	return pile

func _make_mini_token(token_type: int, token_name: String, res: TokenResource = null) -> Control:
	const TOKEN_SIZE := 46
	const ICON_SIZE := 26
	var container = Control.new()
	container.custom_minimum_size = Vector2(TOKEN_SIZE, TOKEN_SIZE)

	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(token_type, Color(0.3, 0.3, 0.3, 1))
	style.corner_radius_top_left = TOKEN_SIZE / 2.0
	style.corner_radius_top_right = TOKEN_SIZE / 2.0
	style.corner_radius_bottom_left = TOKEN_SIZE / 2.0
	style.corner_radius_bottom_right = TOKEN_SIZE / 2.0
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
		var half := ICON_SIZE / 2.0
		var center := TOKEN_SIZE / 2.0
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = center - half
		icon.offset_top = center - half
		icon.offset_right = -(center - half)
		icon.offset_bottom = -(center - half)
		container.add_child(icon)

	if res != null:
		container.mouse_filter = Control.MOUSE_FILTER_STOP
		container.mouse_entered.connect(func():
			TooltipManager.show_token(res, container.global_position, Vector2(TOKEN_SIZE, TOKEN_SIZE))
		)
		container.mouse_exited.connect(func():
			TooltipManager.hide_tooltip()
		)

	return container
