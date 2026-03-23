class_name BattleHUD
extends Node


var _s: CanvasItem  # reference to battle_scene instance

func setup(scene: CanvasItem) -> void:
	_s = scene

func update_hud() -> void:
	_s.label_gold.text = "%d" % GameManager.gold

func update_player_hp() -> void:
	GameManager.player_current_hp = _s.player_current_hp
	_s.label_player_hp.text = "%d/%d" % [_s.player_current_hp, GameManager.player_max_hp]
	var t = _s.create_tween()
	t.tween_property(_s.player_hp_bar, "value", _s.player_current_hp, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func update_draw_pile(bag_manager) -> void:
	var bag_size: int = bag_manager.bag.size()
	_s.draw_count_label.text = "%d" % bag_size

	# Rebuild stacked pile circles below DRAW button
	for child in _s.draw_pile_stack.get_children():
		child.queue_free()
	var pile_style := StyleBoxFlat.new()
	pile_style.bg_color = Color(0.08, 0.08, 0.08, 1)
	pile_style.corner_radius_top_left = 70
	pile_style.corner_radius_top_right = 70
	pile_style.corner_radius_bottom_right = 70
	pile_style.corner_radius_bottom_left = 70
	pile_style.border_width_left = 5
	pile_style.border_width_top = 5
	pile_style.border_width_right = 5
	pile_style.border_width_bottom = 5
	pile_style.border_color = Color(1, 1, 1, 1)
	# Add bottom-to-top so top circle is last child (renders in front)
	for i in range(bag_size - 1, -1, -1):
		var circle := Panel.new()
		circle.size = Vector2(110, 110)
		circle.custom_minimum_size = Vector2(110, 110)
		circle.add_theme_stylebox_override("panel", pile_style)
		circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.position = Vector2(0, i * 80)
		_s.draw_pile_stack.add_child(circle)

	for child in _s.type_breakdown_box.get_children():
		child.queue_free()

	var counts := {
		TokenResource.TokenType.ATTACK: 0,
		TokenResource.TokenType.DEFENSE: 0,
		TokenResource.TokenType.MODIFIER: 0,
		TokenResource.TokenType.HAZARD: 0,
	}
	for token in bag_manager.bag:
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
		_s.type_breakdown_box.add_child(row)

static func _stat_formula(base: float, count: int) -> String:
	if count == 0:
		return "0"
	return _fmt_number(base * count)

static func _fmt_number(v: float) -> String:
	if v == float(int(v)):
		return "%d" % int(v)
	return "%.1f" % v

static func _formula_bbcode(formula: String) -> String:
	return "[center][color=#ffffff]%s[/color][/center]" % formula

func _set_box_color(box: PanelContainer, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_right = 10
	s.corner_radius_bottom_left = 10
	box.add_theme_stylebox_override("panel", s)

func update_combat_line_totals() -> void:
	var cards = _s._get_slot_cards()

	# Bottom bar always shows static base per-token values
	var atk_val := GameManager.base_damage + GameManager.base_damage_fractional
	_s.label_base_damage.text = ("%.1f" % atk_val) if GameManager.base_damage_fractional > 0.0 else ("%d" % GameManager.base_damage)
	_s.label_base_damage.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_s.label_base_defense.text = "%d" % GameManager.base_defense
	_s.label_base_defense.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	if cards.is_empty():
		_s.label_pressure_value.text = "x%.2f" % _s.current_pressure
		_s.vfx.update_vignette(0)
		_s.label_turn_atk.parse_bbcode(_formula_bbcode("0"))
		_s.label_turn_def.parse_bbcode(_formula_bbcode("0"))
		_set_box_color(_s.atk_box, Color(0.1, 0.1, 0.1, 1))
		_set_box_color(_s.def_box, Color(0.1, 0.1, 0.1, 1))
		_s.label_enemy_intention.text = "ENTITY ATTACK ◆ %d" % _s.current_enemy.current_damage
		_s.label_enemy_intention.add_theme_color_override("font_color", intention_color())
		for slot in _s._slots:
			slot.set_effect_state(false)
			if slot.get_card():
				slot.get_card().set_streak_pulse(false)
		return

	var result = TokenEffectResolver.resolve(cards, _s._slots.size())

	_s.label_pressure_value.text = "x%.2f" % _s.current_pressure

	var filled: Array = []
	for slot in _s._slots:
		if not slot.is_empty() and slot.get_card() != null:
			filled.append(slot)
	for i in range(filled.size()):
		var slot = filled[i]
		var card = slot.get_card()
		var color := token_type_color(card.token_data.token_type)
		card.set_inactive(result.inactive_slots.has(i))
		card.set_streak_pulse(result.streak_active_slots.has(i))
		slot.set_streak_active(false)
		slot.set_effect_state(result.placement_active_slots.has(i), color)

	# Show base x count during placement
	var _atk_col := Color(0.91, 0.16, 0.29, 1) if result.atk_count > 0 else Color(1, 1, 1, 1)
	var _def_col := Color(0.24, 0.4, 1, 1) if result.def_count > 0 else Color(1, 1, 1, 1)
	var atk_base := GameManager.base_damage + GameManager.base_damage_fractional
	var atk_str := _stat_formula(atk_base, result.atk_count)
	var def_str := _stat_formula(float(GameManager.base_defense), result.def_count)
	_s.label_turn_atk.parse_bbcode(_formula_bbcode(atk_str))
	_s.label_turn_def.parse_bbcode(_formula_bbcode(def_str))
	var atk_box_col := Color(0.91, 0.16, 0.29, 1) if result.atk_count > 0 else Color(0.1, 0.1, 0.1, 1)
	var def_box_col := Color(0.24, 0.4, 1, 1) if result.def_count > 0 else Color(0.1, 0.1, 0.1, 1)
	_set_box_color(_s.atk_box, atk_box_col)
	_set_box_color(_s.def_box, def_box_col)

	# Enemy intention — arrow when Provocation reduces it
	var shown_damage: int = roundi(_s.current_enemy.current_damage * result.damage_multiplier) if result.damage_multiplier < 1.0 else _s.current_enemy.current_damage
	_s.label_enemy_intention.text = "ENTITY ATTACK ◆ %d" % shown_damage
	_s.label_enemy_intention.add_theme_color_override("font_color", intention_color())

	_s.vfx.update_vignette(_s._count_hazards_in_slots())

func on_enemy_hp_changed(new_hp: int, max_hp: int) -> void:
	_s.label_enemy_hp.text = "%d/%d" % [new_hp, max_hp]
	var t = _s.create_tween()
	t.tween_property(_s.enemy_hp_bar, "value", new_hp, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func on_enemy_intention_changed(intention_type: String, damage: int) -> void:
	_s.label_enemy_intention.text = "ENTITY %s ◆ %d" % [intention_type.to_upper(), damage]

func token_type_color(type: TokenResource.TokenType) -> Color:
	match type:
		TokenResource.TokenType.ATTACK:   return Color("#E8294A")
		TokenResource.TokenType.DEFENSE:  return Color("#3D4CE8")
		TokenResource.TokenType.MODIFIER: return Color("#7B2FE8")
		TokenResource.TokenType.UTILITY:  return Color("#EAA21C")
		_: return Color.WHITE

func intention_color() -> Color:
	return Color.WHITE if GameManager.is_boss_zone() else Color.BLACK

func make_white_stylebox() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.WHITE
	return s
