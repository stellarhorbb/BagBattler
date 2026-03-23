extends Control

@onready var shells_slots:  HBoxContainer = $ContentVBox/SectionsRow/ShellsPanel/VBox/SlotsRow
@onready var token_slots:   HBoxContainer = $ContentVBox/SectionsRow/TokenPanel/VBox/SlotsRow
@onready var echo_slots:    HBoxContainer = $ContentVBox/SectionsRow/EchoPanel/VBox/SlotsRow
@onready var button_reroll: Button        = $ContentVBox/RerollRow/ButtonReroll
@onready var button_continue: Button      = $ContentVBox/ButtonContinue

var reroll_cost: int = 2
var all_shop_tokens: Array[TokenResource] = []

var ALL_MOON_PHASES: Array = [
	preload("res://resources/moon_phases/new_moon.tres"),
	preload("res://resources/moon_phases/first_quarter.tres"),
	preload("res://resources/moon_phases/full_moon.tres"),
	preload("res://resources/moon_phases/last_quarter.tres"),
]

const MOON_PHASE_COLORS := {
	0: Color("#E8294A"), 1: Color("#E8A020"),
	2: Color("#3D4CE8"), 3: Color("#2DB87A"), 4: Color("#C040E0"),
}
const MOON_PHASE_SYMBOLS := {
	0: "🌑", 1: "🌓", 2: "🌕", 3: "🌗", 4: "🩸",
}

var _shell_tooltip: Control = null

const ALL_SHELLS: Array = [
	preload("res://resources/shells/dark_shell.tres"),
	preload("res://resources/shells/striped_shell.tres"),
	preload("res://resources/shells/nacre_shell.tres"),
	preload("res://resources/shells/broken_shell.tres"),
]

var ALL_RELICS: Array = [
	[preload("res://resources/relics/crown_of_fool.tres"), RelicCrownOfFool],
	[preload("res://resources/relics/jellyfish.tres"),     RelicTrident],
	[preload("res://resources/relics/angel.tres"),         RelicAngel],
	[preload("res://resources/relics/white_hole.tres"),    RelicWhiteHole],
	[preload("res://resources/relics/salto.tres"),         RelicSalto],
]

const SHELL_COLORS := {
	0: Color("#2D1B4E"),  # DARK
	1: Color("#C8A050"),  # STRIPED
	2: Color("#C8B8E8"),  # NACRE
	3: Color("#7A5038"),  # BROKEN
}

const SHELL_ICONS := {
	0: "res://assets/icons/shells/new/echo-shell.png",
	1: "res://assets/icons/shells/new/token-shell.png",
	2: "res://assets/icons/shells/new/moon-shell.png",
	3: "res://assets/icons/shells/new/sacrifice-shell.png",
}

var _font       = preload("res://font/LondrinaSolid-Black.ttf")
var _token_card = preload("res://token_card.tscn")
var _relic_card = preload("res://relic_card.tscn")
var _salt_icon  = preload("res://assets/icons/ui/salt-icon.png")

func _ready() -> void:
	all_shop_tokens = [
		preload("res://resources/tokens/strike.tres"),
		preload("res://resources/tokens/guard.tres"),
		preload("res://resources/tokens/provocation.tres"),
		preload("res://resources/tokens/rampart.tres"),
		preload("res://resources/tokens/heal.tres"),
	]
	_populate_shop()
	RunHUD.visible = true
	RunHUD.set_info_color(Color.WHITE)
	RunHUD.refresh()

# ── POPULATE ─────────────────────────────────────────────────────────────────

func _populate_shop() -> void:
	for row in [shells_slots, token_slots, echo_slots]:
		for child in row.get_children():
			child.queue_free()
	_build_shells_section()
	_build_token_section()
	_build_echo_section()
	_update_reroll_button()

func _reroll_right() -> void:
	for row in [token_slots, echo_slots]:
		for child in row.get_children():
			child.queue_free()
	_build_token_section()
	_build_echo_section()
	_update_reroll_button()

func _build_shells_section() -> void:
	var nacre: ShellResource = preload("res://resources/shells/nacre_shell.tres")
	var other_pool: Array = ALL_SHELLS.filter(func(s): return s != nacre)
	other_pool.shuffle()
	shells_slots.add_child(_make_shell_slot(nacre))
	shells_slots.add_child(_make_shell_slot(other_pool[0]))

func _build_token_section() -> void:
	if randf() < 0.25:
		token_slots.add_child(_make_moon_phase_slot(_pick_random_moon_phase()))
		return
	var token = _pick_weighted_token()
	var price = token.shop_price if token.shop_price > 0 else roundi(10.0 / token.shop_drop_weight)
	token_slots.add_child(_make_token_slot(token, price))

func _build_echo_section() -> void:
	if randf() < 0.25:
		echo_slots.add_child(_make_moon_phase_slot(_pick_random_moon_phase()))
		return
	var pool: Array = ALL_RELICS.duplicate()
	pool.shuffle()
	var entry = pool[0]
	var data: RelicResource = entry[0]
	var relic_class = entry[1]
	var owned = GameManager.purchased_relics.any(func(r): return r.relic_data == data)
	echo_slots.add_child(_make_relic_slot(data, relic_class, owned))

func _pick_random_moon_phase() -> MoonPhaseResource:
	var pool: Array = ALL_MOON_PHASES.duplicate()
	pool.shuffle()
	return pool[0]

# ── MOON PHASE DIRECT SLOT ────────────────────────────────────────────────────

func _make_moon_phase_slot(phase: MoonPhaseResource) -> VBoxContainer:
	var slot = VBoxContainer.new()
	slot.add_theme_constant_override("separation", 10)
	slot.alignment = BoxContainer.ALIGNMENT_CENTER

	var phase_color: Color = MOON_PHASE_COLORS.get(phase.phase_type, Color.WHITE)

	var circle = Panel.new()
	circle.custom_minimum_size = Vector2(110, 110)
	var cs = StyleBoxFlat.new()
	cs.bg_color = phase_color.darkened(0.45)
	cs.corner_radius_top_left    = 55
	cs.corner_radius_top_right   = 55
	cs.corner_radius_bottom_left = 55
	cs.corner_radius_bottom_right = 55
	cs.border_width_left   = 5
	cs.border_width_top    = 5
	cs.border_width_right  = 5
	cs.border_width_bottom = 5
	cs.border_color = phase_color
	circle.add_theme_stylebox_override("panel", cs)
	var sym = Label.new()
	sym.text = MOON_PHASE_SYMBOLS.get(phase.phase_type, "?")
	sym.add_theme_font_size_override("font_size", 52)
	sym.set_anchors_preset(Control.PRESET_FULL_RECT)
	sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(sym)
	slot.add_child(circle)

	_add_name_label_colored(slot, phase.phase_name, phase_color)

	var desc_lbl = Label.new()
	desc_lbl.text = phase.description
	desc_lbl.add_theme_font_override("font", _font)
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(120, 0)
	slot.add_child(desc_lbl)

	var buy_btn = _make_styled_button("BUY", Color.WHITE, Color(0.1, 0.1, 0.1, 1))
	slot.add_child(buy_btn)
	slot.add_child(_make_price_row(phase.cost))
	buy_btn.pressed.connect(func():
		if GameManager.gold < phase.cost:
			return
		GameManager.gold -= phase.cost
		GameManager.apply_moon_phase(phase)
		_make_sold_out(slot)
		_update_display()
	)
	return slot

# ── SHELL SLOT ────────────────────────────────────────────────────────────────

func _make_shell_slot(shell: ShellResource) -> VBoxContainer:
	var slot = VBoxContainer.new()
	slot.add_theme_constant_override("separation", 10)
	slot.alignment = BoxContainer.ALIGNMENT_CENTER

	# Wrapper so VBoxContainer doesn't fight the vibration tween
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(110, 110)
	wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.add_child(wrapper)

	var circle = TextureRect.new()
	circle.texture = load(SHELL_ICONS.get(shell.shell_type, SHELL_ICONS[0]))
	circle.set_anchors_preset(Control.PRESET_FULL_RECT)
	circle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	circle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	circle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(circle)

	var name_lbl = Label.new()
	name_lbl.text = shell.shell_name.to_upper()
	name_lbl.add_theme_font_override("font", _font)
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.add_child(name_lbl)

	wrapper.mouse_entered.connect(func(): _show_shell_tooltip(shell, wrapper))
	wrapper.mouse_exited.connect(func(): _hide_shell_tooltip())

	var buy_btn = _make_styled_button("BUY", Color.WHITE, Color(0.1, 0.1, 0.1, 1))
	slot.add_child(buy_btn)
	slot.add_child(_make_price_row(shell.cost))

	buy_btn.pressed.connect(func(): _on_buy_shell(shell, circle, slot))
	return slot

# ── SHELL PURCHASE FLOW ───────────────────────────────────────────────────────

func _on_buy_shell(shell: ShellResource, shell_icon: Control, slot: VBoxContainer) -> void:
	if GameManager.gold < shell.cost:
		return
	GameManager.gold -= shell.cost
	_update_display()
	_hide_shell_tooltip()
	for child in slot.get_children():
		if child is Button:
			(child as Button).disabled = true
	await _vibrate_shell(shell_icon)
	_make_sold_out(slot)
	_show_shell_overlay(shell)

func _vibrate_shell(icon: Control) -> void:
	var base_pos := icon.position
	var elapsed := 0.0
	var duration := 0.8
	while elapsed < duration:
		var progress := elapsed / duration
		var intensity := 2.0 + progress * 9.0
		var t = create_tween()
		t.tween_property(icon, "position",
			base_pos + Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.35, intensity * 0.35)), 0.04)
		await t.finished
		elapsed += 0.04
	icon.position = base_pos

# ── SHELL HOVER TOOLTIP ───────────────────────────────────────────────────────

func _show_shell_tooltip(shell: ShellResource, anchor: Control) -> void:
	_hide_shell_tooltip()

	var tooltip = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0, 0, 0, 1)
	ps.border_width_left   = 4
	ps.border_width_top    = 4
	ps.border_width_right  = 4
	ps.border_width_bottom = 4
	ps.border_color = Color(1, 1, 1, 1)
	ps.corner_radius_top_left    = 12
	ps.corner_radius_top_right   = 12
	ps.corner_radius_bottom_left = 12
	ps.corner_radius_bottom_right = 12
	ps.content_margin_left   = 4
	ps.content_margin_top    = 4
	ps.content_margin_right  = 4
	ps.content_margin_bottom = 4
	tooltip.custom_minimum_size = Vector2(320, 0)
	tooltip.add_theme_stylebox_override("panel", ps)
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.z_index = 50

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_top",    24)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_bottom", 24)
	tooltip.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = shell.shell_name.to_upper()
	name_lbl.add_theme_font_override("font", _font)
	name_lbl.add_theme_font_size_override("font_size", 52)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.color = Color(1, 1, 1, 0.15)
	vbox.add_child(divider)

	var desc_lbl = Label.new()
	desc_lbl.text = shell.flavor_text
	desc_lbl.add_theme_font_override("font", _font)
	desc_lbl.add_theme_font_size_override("font_size", 26)
	desc_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	add_child(tooltip)
	_shell_tooltip = tooltip

	# Position above the anchor, same logic as TooltipManager._reposition
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(tooltip):
		return
	tooltip.reset_size()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var tw: float = tooltip.size.x
	var th: float = tooltip.size.y
	var gp: Vector2 = anchor.global_position
	var x := gp.x + 55.0 - tw * 0.5
	var y := gp.y - th - 20.0
	if y < 8.0:
		y = gp.y + anchor.size.y + 20.0
	tooltip.global_position = Vector2(clamp(x, 8.0, vp.x - tw - 8.0), clamp(y, 8.0, vp.y - th - 8.0))

func _hide_shell_tooltip() -> void:
	if is_instance_valid(_shell_tooltip):
		_shell_tooltip.queue_free()
	_shell_tooltip = null

# ── SHELL CHOICE OVERLAY ──────────────────────────────────────────────────────

func _show_shell_overlay(shell: ShellResource) -> void:
	var choices := _get_shell_choices(shell)
	var shell_color: Color = SHELL_COLORS.get(shell.shell_type, Color.WHITE)
	var is_broken := shell.shell_type == ShellResource.ShellType.BROKEN

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = shell.shell_name.to_upper()
	title_lbl.add_theme_font_override("font", _font)
	title_lbl.add_theme_font_size_override("font_size", 72)
	title_lbl.add_theme_color_override("font_color", shell_color)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var is_blood_moon := (not is_broken) and choices.size() == 1
	var sub_lbl = Label.new()
	sub_lbl.text = "REMOVE ONE" if is_broken else ("A GIFT FROM THE DEPTHS" if is_blood_moon else "CHOOSE ONE")
	sub_lbl.add_theme_font_override("font", _font)
	sub_lbl.add_theme_font_size_override("font_size", 28)
	sub_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub_lbl)

	if choices.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "NOTHING AVAILABLE"
		empty_lbl.add_theme_font_override("font", _font)
		empty_lbl.add_theme_font_size_override("font_size", 32)
		empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 1))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_lbl)
	else:
		var cards_row = HBoxContainer.new()
		cards_row.add_theme_constant_override("separation", 40)
		cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(cards_row)
		for choice in choices:
			cards_row.add_child(_make_choice_card(choice, shell, overlay))

	var skip_btn = _make_styled_button("SKIP", Color(0.22, 0.22, 0.22, 1), Color(0.7, 0.7, 0.7, 1))
	skip_btn.custom_minimum_size = Vector2(160, 48)
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_btn.pressed.connect(overlay.queue_free)
	vbox.add_child(skip_btn)

func _get_shell_choices(shell: ShellResource) -> Array:
	match shell.shell_type:
		ShellResource.ShellType.DARK:
			var pool: Array = ALL_RELICS.duplicate()
			pool.shuffle()
			return pool.slice(0, 2)
		ShellResource.ShellType.STRIPED:
			var pool: Array = all_shop_tokens.duplicate()
			pool.shuffle()
			var picks: Array = []
			for t in pool.slice(0, 2):
				picks.append({type = "token", resource = t})
			return picks
		ShellResource.ShellType.NACRE:
			if randf() < 0.05:
				return [{type = "moon_phase", resource = preload("res://resources/moon_phases/blood_moon.tres")}]
			var pool: Array = ALL_MOON_PHASES.duplicate()
			pool.shuffle()
			var picks: Array = []
			for p in pool.slice(0, 2):
				picks.append({type = "moon_phase", resource = p})
			return picks
		ShellResource.ShellType.BROKEN:
			var pool: Array = []
			for t in GameManager.full_bag:
				if t.token_type != TokenResource.TokenType.HAZARD:
					pool.append(t)
			pool.shuffle()
			var picks: Array = []
			for t in pool.slice(0, min(3, pool.size())):
				picks.append({type = "remove_token", resource = t})
			return picks
	return []

func _make_choice_card(choice: Variant, shell: ShellResource, overlay: Control) -> VBoxContainer:
	var card_slot = VBoxContainer.new()
	card_slot.add_theme_constant_override("separation", 12)
	card_slot.alignment = BoxContainer.ALIGNMENT_CENTER

	match shell.shell_type:
		ShellResource.ShellType.DARK:
			var data: RelicResource = choice[0]
			var relic_class = choice[1]
			var already_owned = GameManager.purchased_relics.any(func(r): return r.relic_data == data)
			var icon = _relic_card.instantiate()
			icon.custom_minimum_size = Vector2(110, 110)
			card_slot.add_child(icon)
			icon.call_deferred("setup", data)
			_add_name_label(card_slot, data.relic_name)
			if already_owned:
				_add_dim_label(card_slot, "OWNED")
			else:
				var btn = _make_styled_button("TAKE", Color.WHITE, Color(0.1, 0.1, 0.1, 1))
				btn.pressed.connect(func():
					var instance: BaseRelic = relic_class.new()
					if RelicManager.add_relic(instance):
						GameManager.purchased_relics.append(instance)
					overlay.queue_free()
					_update_display()
				)
				card_slot.add_child(btn)

		ShellResource.ShellType.STRIPED:
			var token: TokenResource = choice["resource"]
			var icon: Control = _token_card.instantiate()
			card_slot.add_child(icon)
			icon.call_deferred("setup", token)
			_add_name_label(card_slot, token.token_name)
			var btn = _make_styled_button("TAKE", Color.WHITE, Color(0.1, 0.1, 0.1, 1))
			btn.pressed.connect(func():
				GameManager.purchased_tokens.append(token)
				GameManager.full_bag.append(token)
				overlay.queue_free()
				_update_display()
			)
			card_slot.add_child(btn)

		ShellResource.ShellType.NACRE:
			var phase: MoonPhaseResource = choice["resource"]
			var phase_color: Color = MOON_PHASE_COLORS.get(phase.phase_type, Color.WHITE)
			var circle = Panel.new()
			circle.custom_minimum_size = Vector2(110, 110)
			var cs = StyleBoxFlat.new()
			cs.bg_color = phase_color.darkened(0.45)
			cs.corner_radius_top_left    = 55
			cs.corner_radius_top_right   = 55
			cs.corner_radius_bottom_left = 55
			cs.corner_radius_bottom_right = 55
			cs.border_width_left   = 5
			cs.border_width_top    = 5
			cs.border_width_right  = 5
			cs.border_width_bottom = 5
			cs.border_color = phase_color
			circle.add_theme_stylebox_override("panel", cs)
			circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sym = Label.new()
			sym.text = MOON_PHASE_SYMBOLS.get(phase.phase_type, "?")
			sym.add_theme_font_size_override("font_size", 52)
			sym.set_anchors_preset(Control.PRESET_FULL_RECT)
			sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
			circle.add_child(sym)
			card_slot.add_child(circle)
			_add_name_label_colored(card_slot, phase.phase_name, phase_color)
			var desc_lbl = Label.new()
			desc_lbl.text = phase.description
			desc_lbl.add_theme_font_override("font", _font)
			desc_lbl.add_theme_font_size_override("font_size", 16)
			desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
			desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.custom_minimum_size = Vector2(120, 0)
			card_slot.add_child(desc_lbl)
			var btn = _make_styled_button("TAKE", Color.WHITE, Color(0.1, 0.1, 0.1, 1))
			btn.pressed.connect(func():
				GameManager.apply_moon_phase(phase)
				overlay.queue_free()
				_update_display()
			)
			card_slot.add_child(btn)

		ShellResource.ShellType.BROKEN:
			var token: TokenResource = choice["resource"]
			var icon: Control = _token_card.instantiate()
			card_slot.add_child(icon)
			icon.call_deferred("setup", token)
			_add_name_label(card_slot, token.token_name)
			var btn = _make_styled_button("REMOVE", Color("#E8294A"), Color.WHITE)
			btn.pressed.connect(func():
				var idx = GameManager.full_bag.find(token)
				if idx != -1:
					GameManager.full_bag.remove_at(idx)
					GameManager.sacrificed_tokens.append(token)
				overlay.queue_free()
				_update_display()
			)
			card_slot.add_child(btn)

	return card_slot

# ── TOKEN / RELIC SLOTS ───────────────────────────────────────────────────────

func _make_token_slot(token: TokenResource, price: int) -> VBoxContainer:
	var slot = VBoxContainer.new()
	slot.add_theme_constant_override("separation", 10)
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon: Control = _token_card.instantiate()
	slot.add_child(icon)
	icon.call_deferred("setup", token)
	var buy_btn = _make_styled_button("BUY", Color.WHITE, Color(0.1, 0.1, 0.1, 1))
	slot.add_child(buy_btn)
	slot.add_child(_make_price_row(price))
	buy_btn.pressed.connect(func(): _on_buy_token(token, price, slot))
	return slot

func _make_relic_slot(data: RelicResource, relic_class: GDScript, already_owned: bool) -> VBoxContainer:
	var slot = VBoxContainer.new()
	slot.add_theme_constant_override("separation", 10)
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon = _relic_card.instantiate()
	icon.custom_minimum_size = Vector2(110, 110)
	slot.add_child(icon)
	icon.call_deferred("setup", data)
	if already_owned:
		_add_dim_label(slot, "OWNED")
	else:
		var buy_btn = _make_styled_button("BUY", Color.WHITE, Color(0.1, 0.1, 0.1, 1))
		slot.add_child(buy_btn)
		slot.add_child(_make_price_row(data.cost))
		buy_btn.pressed.connect(func(): _on_buy_relic(data, relic_class, slot))
	return slot

func _make_sold_out(slot: VBoxContainer) -> void:
	for child in slot.get_children():
		child.queue_free()
	var circle = Panel.new()
	circle.custom_minimum_size = Vector2(110, 110)
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color(0.07, 0.07, 0.07, 1)
	cs.corner_radius_top_left    = 55
	cs.corner_radius_top_right   = 55
	cs.corner_radius_bottom_left = 55
	cs.corner_radius_bottom_right = 55
	circle.add_theme_stylebox_override("panel", cs)
	slot.add_child(circle)
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(110, 44)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.22, 0.22, 0.22, 1)
	bs.corner_radius_top_left    = 8
	bs.corner_radius_top_right   = 8
	bs.corner_radius_bottom_left = 8
	bs.corner_radius_bottom_right = 8
	badge.add_theme_stylebox_override("panel", bs)
	var lbl = Label.new()
	lbl.text = "SOLD OUT"
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(lbl)
	slot.add_child(badge)

# ── PURCHASE HANDLERS ─────────────────────────────────────────────────────────

func _on_buy_token(token: TokenResource, price: int, slot: VBoxContainer) -> void:
	if GameManager.gold < price:
		return
	GameManager.gold -= price
	GameManager.purchased_tokens.append(token)
	GameManager.full_bag.append(token)
	_make_sold_out(slot)
	_update_display()

func _on_buy_relic(data: RelicResource, relic_class: GDScript, slot: VBoxContainer) -> void:
	if GameManager.gold < data.cost:
		return
	var instance: BaseRelic = relic_class.new()
	if not RelicManager.add_relic(instance):
		return
	GameManager.gold -= data.cost
	GameManager.purchased_relics.append(instance)
	_make_sold_out(slot)
	_update_display()

func _on_reroll_pressed() -> void:
	if GameManager.gold < reroll_cost:
		return
	GameManager.gold -= reroll_cost
	reroll_cost += 2
	_reroll_right()
	_update_display()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://battle_scene.tscn")

# ── HELPERS ───────────────────────────────────────────────────────────────────

func _pick_weighted_token() -> TokenResource:
	var total = 0.0
	for t in all_shop_tokens:
		total += t.shop_drop_weight
	var roll = randf() * total
	var cumulative = 0.0
	var picked: TokenResource = all_shop_tokens[0]
	for t in all_shop_tokens:
		cumulative += t.shop_drop_weight
		if roll <= cumulative:
			picked = t
			break
	return picked

func _add_name_label(parent: Control, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func _add_name_label_colored(parent: Control, text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func _add_dim_label(parent: Control, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func _make_styled_button(text: String, bg: Color, fg: Color) -> Button:
	var sn = StyleBoxFlat.new()
	sn.bg_color = bg
	sn.corner_radius_top_left    = 8
	sn.corner_radius_top_right   = 8
	sn.corner_radius_bottom_right = 8
	sn.corner_radius_bottom_left  = 8
	var sd = StyleBoxFlat.new()
	sd.bg_color = Color(0.3, 0.3, 0.3, 1)
	sd.corner_radius_top_left    = 8
	sd.corner_radius_top_right   = 8
	sd.corner_radius_bottom_right = 8
	sd.corner_radius_bottom_left  = 8
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(110, 44)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color",          fg)
	btn.add_theme_color_override("font_hover_color",    fg)
	btn.add_theme_color_override("font_pressed_color",  fg)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55, 1))
	btn.add_theme_stylebox_override("normal",   sn)
	btn.add_theme_stylebox_override("hover",    sn)
	btn.add_theme_stylebox_override("pressed",  sn)
	btn.add_theme_stylebox_override("disabled", sd)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	return btn

func _make_price_row(price: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl = Label.new()
	lbl.text = "%d" % price
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var icon = TextureRect.new()
	icon.texture = _salt_icon
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	return row

func _update_reroll_button() -> void:
	button_reroll.text = "REROLL  %d" % reroll_cost

func _update_display() -> void:
	RunHUD.refresh()
	_update_reroll_button()
