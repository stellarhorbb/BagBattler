extends Control

@onready var tokens_slots:  HBoxContainer = $ContentVBox/SectionsRow/TokensPanel/VBox/SlotsRow
@onready var echoes_slots:  HBoxContainer = $ContentVBox/SectionsRow/EchoesPanel/VBox/SlotsRow
@onready var item_slots:    HBoxContainer = $ContentVBox/SectionsRow/ItemPanel/VBox/SlotsRow
@onready var button_reroll: Button        = $ContentVBox/RerollRow/ButtonReroll
@onready var button_continue: Button      = $ContentVBox/ButtonContinue

var reroll_cost: int = 2
var all_shop_tokens: Array[TokenResource] = []

var _font         = preload("res://font/LondrinaSolid-Black.ttf")
var _token_card   = preload("res://token_card.tscn")
var _relic_card   = preload("res://relic_card.tscn")
var _salt_icon    = preload("res://assets/icons/ui/salt-icon.png")
var _lock_icon    = preload("res://assets/icons/ui/lock.png")

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

# ── POPULATE ────────────────────────────────────────────────────────────────

func _populate_shop() -> void:
	for row in [tokens_slots, echoes_slots, item_slots]:
		for child in row.get_children():
			child.queue_free()

	_build_tokens_section()
	_build_echoes_section()
	_build_item_section()
	_update_reroll_button()

func _build_tokens_section() -> void:
	for _i in 3:
		var token = _pick_weighted_token()
		var price = token.shop_price if token.shop_price > 0 else roundi(10.0 / token.shop_drop_weight)
		tokens_slots.add_child(_make_token_slot(token, price))

func _build_echoes_section() -> void:
	var shop_relics := [
		[preload("res://resources/relics/crown_of_fool.tres"), RelicCrownOfFool],
		[preload("res://resources/relics/jellyfish.tres"),     RelicTrident],
		[preload("res://resources/relics/angel.tres"),         RelicAngel],
	]
	var entry       = shop_relics[randi() % shop_relics.size()]
	var data: RelicResource = entry[0]
	var relic_class = entry[1]
	var owned = GameManager.purchased_relics.any(func(r): return r.relic_data == data)
	echoes_slots.add_child(_make_relic_slot(data, relic_class, owned))

func _build_item_section() -> void:
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var icon = TextureRect.new()
	icon.texture = _lock_icon
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(0.45, 0.45, 0.45, 1)
	center.add_child(icon)
	item_slots.add_child(center)

# ── SLOTS ────────────────────────────────────────────────────────────────────

func _make_token_slot(token: TokenResource, price: int) -> VBoxContainer:
	var slot = VBoxContainer.new()
	slot.add_theme_constant_override("separation", 10)
	slot.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon: Control = _token_card.instantiate()
	slot.add_child(icon)
	icon.call_deferred("setup", token)

	var buy_btn = _make_buy_button()
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
		var owned_lbl = Label.new()
		owned_lbl.text = "OWNED"
		owned_lbl.add_theme_font_override("font", _font)
		owned_lbl.add_theme_font_size_override("font_size", 20)
		owned_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		slot.add_child(owned_lbl)
	else:
		var buy_btn = _make_buy_button()
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

# ── BUY HELPERS ──────────────────────────────────────────────────────────────

func _make_buy_button() -> Button:
	var sn = StyleBoxFlat.new()
	sn.bg_color = Color.WHITE
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
	btn.text = "BUY"
	btn.custom_minimum_size = Vector2(110, 44)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color",         Color(0.1, 0.1, 0.1, 1))
	btn.add_theme_color_override("font_hover_color",   Color(0.1, 0.1, 0.1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.1, 0.1, 1))
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

# ── PURCHASE HANDLERS ────────────────────────────────────────────────────────

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
	_populate_shop()
	_update_display()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://battle_scene.tscn")

# ── UTILITY ──────────────────────────────────────────────────────────────────

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

func _update_reroll_button() -> void:
	button_reroll.text = "REROLL  %d" % reroll_cost

func _update_display() -> void:
	RunHUD.refresh()
	_update_reroll_button()
