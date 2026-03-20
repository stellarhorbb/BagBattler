extends CanvasLayer

var label_turns: Label
var label_turns_title: Label
var label_salt_title: Label
var label_gold: Label
var _salt_icon: TextureRect

const _SALT_ICON_DARK = preload("res://assets/icons/ui/salt-icon-black.png")
const _SALT_ICON_LIGHT = preload("res://assets/icons/ui/salt-icon.png")
var relic_line: Node
var player_hp_bar: ProgressBar
var label_player_hp: Label
var label_base_damage: Label
var label_base_defense: Label
var draw_count_label: Label
var type_breakdown_box: VBoxContainer
var bag_info_area: Control
var bag_inspector: Control
var _bag_hover_active := false
var _modal_panel: Control

func _ready() -> void:
	layer = 5
	visible = false
	var root = preload("res://run_hud.tscn").instantiate()
	add_child(root)

	label_turns_title = root.get_node("TurnSection/LabelTurnsTitle")
	label_turns = root.get_node("TurnSection/LabelTurns")
	label_salt_title = root.get_node("SaltSection/LabelSaltTitle")
	label_gold = root.get_node("SaltSection/GoldRow/LabelGold")
	_salt_icon = root.get_node("SaltSection/GoldRow/SaltIcon")
	relic_line = root.get_node("PlayerBottomBar/CenterSection/RelicLine")
	player_hp_bar = root.get_node("PlayerBottomBar/CenterSection/PlayerHPBar")
	label_player_hp = root.get_node("PlayerBottomBar/CenterSection/BottomStatsRow/LabelPlayerHP")
	label_base_damage = root.get_node("PlayerBottomBar/CenterSection/BottomStatsRow/ATKStatLeft/LabelBaseDamage")
	label_base_defense = root.get_node("PlayerBottomBar/CenterSection/BottomStatsRow/DEFStatRight/LabelBaseDefense")
	draw_count_label = root.get_node("BagInfoArea/DrawCountLabel")
	type_breakdown_box = root.get_node("BagInfoArea/TypeBreakdownBox")
	bag_info_area = root.get_node("BagInfoArea")

	bag_inspector = preload("res://bag_inspector.tscn").instantiate()
	bag_inspector.get_node("CompactView").visible = false
	add_child(bag_inspector)
	_modal_panel = bag_inspector.get_node("ModalView/ModalPanel")
	bag_info_area.mouse_entered.connect(func():
		_bag_hover_active = true
		bag_inspector.open_modal()
	)

func refresh() -> void:
	var display_ante := GameManager.get_current_ante() - 1
	var display_round := GameManager.get_round_in_ante()
	label_turns_title.text = GameManager.get_depth_name().to_upper()
	label_turns.text = "%d.%d" % [display_ante, display_round]
	label_gold.text = "%d" % GameManager.gold
	player_hp_bar.max_value = GameManager.player_max_hp
	player_hp_bar.value = GameManager.player_current_hp
	label_player_hp.text = "%d/%d" % [GameManager.player_current_hp, GameManager.player_max_hp]
	var atk_val := GameManager.base_damage + GameManager.base_damage_fractional
	label_base_damage.text = ("%.1f" % atk_val) if GameManager.base_damage_fractional > 0.0 else ("%d" % GameManager.base_damage)
	label_base_defense.text = "%d" % GameManager.base_defense
	relic_line.refresh()
	update_bag_info(GameManager.get_effective_bag())
	bag_inspector.setup_from_array(GameManager.full_bag)

func _process(_delta: float) -> void:
	if not _bag_hover_active or not bag_inspector.get_node("ModalView").visible:
		return
	var mouse := get_viewport().get_mouse_position()
	if not bag_info_area.get_global_rect().has_point(mouse) \
			and not _modal_panel.get_global_rect().has_point(mouse):
		_bag_hover_active = false
		bag_inspector.close_modal()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or bag_inspector == null:
		return
	if event is InputEventKey and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		if event.pressed:
			bag_inspector.open_modal()
		else:
			bag_inspector.close_modal()

func set_info_color(color: Color) -> void:
	label_turns_title.add_theme_color_override("font_color", color)
	label_turns.add_theme_color_override("font_color", color)
	label_salt_title.add_theme_color_override("font_color", color)
	label_gold.add_theme_color_override("font_color", color)
	_salt_icon.texture = _SALT_ICON_LIGHT if color == Color.WHITE else _SALT_ICON_DARK

func update_bag_info(tokens: Array) -> void:
	draw_count_label.text = "%d" % tokens.size()
	_rebuild_type_breakdown(tokens)

func _rebuild_type_breakdown(tokens: Array) -> void:
	for child in type_breakdown_box.get_children():
		child.queue_free()

	var counts := {
		TokenResource.TokenType.ATTACK: 0,
		TokenResource.TokenType.DEFENSE: 0,
		TokenResource.TokenType.MODIFIER: 0,
		TokenResource.TokenType.HAZARD: 0,
	}
	for token in tokens:
		if counts.has(token.token_type):
			counts[token.token_type] += 1

	var type_colors := {
		TokenResource.TokenType.ATTACK:   Color("#E8294A"),
		TokenResource.TokenType.DEFENSE:  Color("#3D4CE8"),
		TokenResource.TokenType.MODIFIER: Color("#7B2FE8"),
		TokenResource.TokenType.HAZARD:   Color("#333333"),
	}

	for type in [TokenResource.TokenType.ATTACK, TokenResource.TokenType.DEFENSE, TokenResource.TokenType.MODIFIER, TokenResource.TokenType.HAZARD]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(28, 28)
		var style := StyleBoxFlat.new()
		style.bg_color = type_colors[type]
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_right = 14
		style.corner_radius_bottom_left = 14
		dot.add_theme_stylebox_override("panel", style)

		var lbl := Label.new()
		lbl.text = "%d" % counts[type]
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		row.add_child(dot)
		row.add_child(lbl)
		type_breakdown_box.add_child(row)
