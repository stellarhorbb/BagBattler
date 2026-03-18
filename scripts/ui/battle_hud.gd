class_name BattleHUD
extends Node

var _s: CanvasItem  # reference to battle_scene instance

func setup(scene: CanvasItem) -> void:
	_s = scene

func update_hud() -> void:
	_s.label_turns.text = "%d" % _s.turns_played
	_s.label_gold.text = "♦ %d" % GameManager.gold

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
		circle.size = Vector2(140, 140)
		circle.custom_minimum_size = Vector2(140, 140)
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

func update_combat_line_totals() -> void:
	var cards = _s._get_slot_cards()

	_s.label_pressure_value.text = "x%.1f" % _s.current_pressure

	# Bottom bar always shows static base per-token values
	_s.label_base_damage.text = "%d" % GameManager.base_damage
	_s.label_base_damage.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_s.label_base_defense.text = "%d" % GameManager.base_defense
	_s.label_base_defense.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	if cards.is_empty():
		_s.vfx.update_vignette(0)
		_s.label_turn_atk.text = "0"
		_s.label_turn_atk.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_s.label_turn_def.text = "0"
		_s.label_turn_def.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_s.label_intention_type.text = "ATTACK"
		_s.label_enemy_intention.text = "◆ %d" % _s.current_enemy.current_damage
		_s.label_enemy_intention.add_theme_color_override("font_color", intention_color())
		_s.label_intention_type.add_theme_color_override("font_color", intention_color())
		for slot in _s._slots:
			slot.set_effect_state(false)
		return

	var result = TokenEffectResolver.resolve(cards)

	# Gather filled slots in order for effect index logic
	var filled: Array = []
	for slot in _s._slots:
		if not slot.is_empty() and slot.get_card() != null:
			filled.append(slot)
	var last_index := filled.size() - 1
	for i in range(filled.size()):
		var slot = filled[i]
		var card = slot.get_card()
		var effect = card.token_data.effect
		var activated := false
		if effect == TokenResource.TokenEffect.PROVOCATION:
			activated = true
		elif effect == TokenResource.TokenEffect.RAMPART and i == last_index:
			for j in range(i):
				if filled[j].get_card().token_data.token_type == TokenResource.TokenType.DEFENSE:
					activated = true
					break
		if not activated and result.active_combo_slots.has(i):
			activated = true
		if activated:
			slot.set_effect_state(true, token_type_color(card.token_data.token_type))
		else:
			slot.set_effect_state(false)

	# Pressure row ATK — use resolved total (includes combo multipliers)
	if result.total_attack > 0:
		_s.label_turn_atk.text = "%d" % result.total_attack
		_s.label_turn_atk.add_theme_color_override("font_color", Color(0.91, 0.16, 0.29, 1))
	else:
		_s.label_turn_atk.text = "0"
		_s.label_turn_atk.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	# Pressure row DEF — show pre→post arrow when Rampart doubles it
	if result.rampart_active:
		var pre_rampart: int = result.total_defense / 2
		_s.label_turn_def.text = "%d → %d" % [pre_rampart, result.total_defense]
		_s.label_turn_def.add_theme_color_override("font_color", Color(0.24, 0.4, 1, 1))
	elif result.total_defense > 0:
		_s.label_turn_def.text = "%d" % result.total_defense
		_s.label_turn_def.add_theme_color_override("font_color", Color(0.24, 0.4, 1, 1))
	else:
		_s.label_turn_def.text = "0"
		_s.label_turn_def.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	# Enemy intention — arrow when Provocation reduces it
	_s.label_intention_type.text = "ATTACK"
	_s.label_intention_type.add_theme_color_override("font_color", intention_color())
	if result.damage_multiplier < 1.0:
		var modified_damage := roundi(_s.current_enemy.current_damage * result.damage_multiplier)
		_s.label_enemy_intention.text = "◆ %d → %d" % [_s.current_enemy.current_damage, modified_damage]
	else:
		_s.label_enemy_intention.text = "◆ %d" % _s.current_enemy.current_damage
	_s.label_enemy_intention.add_theme_color_override("font_color", intention_color())

	_s.vfx.update_vignette(_s._count_hazards_in_slots())

func animate_pressure_on_stat(label: Label, new_text: String, color: Color) -> void:
	label.text = new_text
	label.add_theme_color_override("font_color", color)
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

func on_enemy_hp_changed(new_hp: int, max_hp: int) -> void:
	_s.label_enemy_hp.text = "%d/%d" % [new_hp, max_hp]
	var t = _s.create_tween()
	t.tween_property(_s.enemy_hp_bar, "value", new_hp, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func on_enemy_intention_changed(_intention_type: String, damage: int) -> void:
	_s.label_enemy_intention.text = "◆ %d" % damage

func token_type_color(type: TokenResource.TokenType) -> Color:
	match type:
		TokenResource.TokenType.ATTACK:  return Color("#E8294A")
		TokenResource.TokenType.DEFENSE: return Color("#3D4CE8")
		TokenResource.TokenType.MODIFIER: return Color("#7B2FE8")
		_: return Color.WHITE

func intention_color() -> Color:
	return Color.WHITE if GameManager.is_boss_round() else Color.BLACK

func make_white_stylebox() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.WHITE
	return s
