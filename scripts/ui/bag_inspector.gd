extends Control

@onready var compact_view = $CompactView
@onready var modal_view = $ModalView
@onready var modal_content = $ModalView/ScrollContainer/ModalContent
@onready var circles_container = $CompactView/CirclesContainer

var bag_manager: BagManager

# Couleurs par type de jeton
const TYPE_COLORS = {
	TokenResource.TokenType.ATTACK: Color("ce002d"),
	TokenResource.TokenType.DEFENSE: Color("004397"),
	TokenResource.TokenType.MODIFIER: Color("6a0dad"),
	TokenResource.TokenType.UTILITY: Color("ffd700"),
	TokenResource.TokenType.CLEANSER: Color("e0e0e0"),
	TokenResource.TokenType.HAZARD: Color("2a2a2a"),
}

func setup(bm: BagManager) -> void:
	bag_manager = bm
	refresh()

func refresh() -> void:
	_build_compact_view()
	if modal_view.visible:
		_build_modal_view()

# --- VUE COMPACTE ---
const TYPE_ORDER = [
	TokenResource.TokenType.ATTACK,
	TokenResource.TokenType.DEFENSE,
	TokenResource.TokenType.MODIFIER,
	TokenResource.TokenType.UTILITY,
	TokenResource.TokenType.CLEANSER,
	TokenResource.TokenType.HAZARD,
]

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

	# Defer size sync so layout has processed the new children
	call_deferred("_sync_compact_size")

# Resize the button rect to match its content after layout
func _sync_compact_size() -> void:
	var content_size = circles_container.get_combined_minimum_size()
	var new_w = content_size.x + 16.0
	var new_h = max(content_size.y + 8.0, 60.0)

	# Anchor is at x=0.5 — keep horizontal center
	compact_view.set_offset(SIDE_LEFT, -new_w / 2.0)
	compact_view.set_offset(SIDE_RIGHT,  new_w / 2.0)

	# Anchor is at y=0.944 — keep vertical center unchanged, update height only
	var v_center = (compact_view.get_offset(SIDE_TOP) + compact_view.get_offset(SIDE_BOTTOM)) / 2.0
	compact_view.set_offset(SIDE_TOP,    v_center - new_h / 2.0)
	compact_view.set_offset(SIDE_BOTTOM, v_center + new_h / 2.0)

# --- MODAL ---
func _build_modal_view() -> void:
	for child in modal_content.get_children():
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

		var header = Label.new()
		header.text = TokenResource.TokenType.keys()[token_type].to_upper()
		header.add_theme_font_size_override("font_size", 20)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		modal_content.add_child(header)

		modal_content.add_child(HSeparator.new())

		if composition.has(token_type):
			var type_data = composition[token_type]
			for token_name in type_data:
				var data = type_data[token_name]
				var row = _make_row(token_type, token_name, data["count"], data["percent"])
				modal_content.add_child(row)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		modal_content.add_child(spacer)

# --- TOGGLE MODAL ---
func _ready() -> void:
	# Render modal above all game UI (CombatLine token cards, buttons, etc.)
	modal_view.z_index = 100
	modal_view.z_as_relative = false

	compact_view.mouse_entered.connect(_on_hover_enter)
	compact_view.mouse_exited.connect(_on_hover_exit)
	modal_view.mouse_exited.connect(_on_hover_exit)

func _on_hover_enter() -> void:
	if not modal_view.visible:
		_build_modal_view()
		_position_modal()
		modal_view.visible = true

func _on_hover_exit() -> void:
	# Short delay so moving the mouse from compact_view to modal_view doesn't flicker
	await get_tree().create_timer(0.08).timeout
	if not is_inside_tree():
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var over_compact = Rect2(compact_view.global_position, compact_view.size).has_point(mouse_pos)
	var over_modal = Rect2(modal_view.global_position, modal_view.size).has_point(mouse_pos)
	if not over_compact and not over_modal:
		_close_modal()

# Position the modal above the compact view, centered horizontally
func _position_modal() -> void:
	var viewport_size = get_viewport_rect().size
	var modal_min = modal_view.get_combined_minimum_size()
	var compact_pos = compact_view.global_position
	var compact_size = compact_view.size

	var mx = compact_pos.x + compact_size.x / 2.0 - modal_min.x / 2.0
	var my = compact_pos.y - modal_min.y - 10.0

	mx = clamp(mx, 10.0, viewport_size.x - modal_min.x - 10.0)
	my = max(my, 10.0)

	modal_view.position = Vector2(mx, my)

func open_modal() -> void:
	if not modal_view.visible:
		_build_modal_view()
		_position_modal()
		modal_view.visible = true

func close_modal() -> void:
	_close_modal()

func _close_modal() -> void:
	modal_view.visible = false

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

	var dot = Panel.new()
	dot.custom_minimum_size = Vector2(20, 20)
	var style = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(token_type, Color.WHITE)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	dot.add_theme_stylebox_override("panel", style)
	row.add_child(dot)

	var name_label = Label.new()
	name_label.text = "  %s  ×%d" % [token_name, count]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	row.add_child(name_label)

	var pct_label = Label.new()
	pct_label.text = "%d%%" % roundi(percent)
	pct_label.add_theme_font_size_override("font_size", 18)
	row.add_child(pct_label)

	return row
