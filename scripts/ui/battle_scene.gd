extends Control

# Enemy zone
@onready var blob_bg = $EnemyZone/BlobBG
@onready var label_enemy_name = $EnemyZone/EnemyContent/NameRow/LabelEnemyName
@onready var label_enemy_hp = $EnemyZone/EnemyContent/NameRow/LabelEnemyHP
@onready var enemy_hp_bar = $EnemyZone/EnemyContent/EnemyHPBar
@onready var label_intention_type = $EnemyZone/IntentionBox/LabelIntentionType
@onready var label_enemy_intention = $EnemyZone/IntentionBox/LabelEnemyIntention

# HUD
@onready var label_turns = $HUDTurns/LabelTurns
@onready var label_turns_title = $HUDTurns/LabelTurnsTitle
@onready var label_gold = $HUDSalt/SaltValueRow/LabelGold
@onready var label_salt_title = $HUDSalt/LabelSaltTitle
@onready var salt_icon = $HUDSalt/SaltValueRow/SaltIcon

# Combat slots + controls
@onready var combat_slots_row = $CombatSlotsRow
@onready var button_execute = $ButtonExecute
@onready var revealed_token_holder = $DrawArea/RevealedTokenHolder

# Draw area
@onready var draw_area = $DrawArea
@onready var button_draw = $DrawArea/ButtonDraw
@onready var draw_pile_stack = $DrawArea/DrawPileStack
@onready var bag_info_area = $DrawArea/BagInfoArea
@onready var draw_count_label = $DrawArea/BagInfoArea/DrawCountLabel
@onready var type_breakdown_box = $DrawArea/BagInfoArea/TypeBreakdownBox

# Preview
@onready var damage_preview_box = $PreviewRow/DamagePreviewBox
@onready var label_damage_preview = $PreviewRow/DamagePreviewBox/LabelDamagePreview
@onready var defense_preview_box = $PreviewRow/DefensePreviewBox
@onready var label_defense_preview = $PreviewRow/DefensePreviewBox/LabelDefensePreview

# Player bottom bar
@onready var relic_line = $PlayerBottomBar/CenterSection/RelicLine
@onready var player_hp_bar = $PlayerBottomBar/CenterSection/PlayerHPBar
@onready var label_player_hp = $PlayerBottomBar/CenterSection/LabelPlayerHP
@onready var label_base_damage = $PlayerBottomBar/LeftStatSection/TopRow/LabelBaseDamage
@onready var label_base_defense = $PlayerBottomBar/RightStatSection/TopRow/LabelBaseDefense

# VFX
@onready var flash_overlay = $FlashOverlay
@onready var vignette_overlay = $VignetteOverlay
@onready var crash_banner = $CrashBanner
@onready var saved_banner = $SavedBanner
var vfx: BattleVFX

# Nav
@onready var button_next = $ButtonNext
@onready var button_back_to_menu = $ButtonBackToMenu

# Bag inspector
@onready var bag_inspector = $BagInspector

# State
var token_card_scene = preload("res://token_card.tscn")
var bag_manager = BagManager
var current_enemy: Enemy
var player_current_hp: int
var turns_played: int = 0
var _slots: Array[Node] = []

# Physics drag state
var _dragging := false
var _drag_card: Control = null
var _drag_token: TokenResource = null
var _drag_velocity := Vector2.ZERO
var _prev_mouse_pos := Vector2.ZERO

func _ready():
	vfx = BattleVFX.new()
	add_child(vfx)
	vfx.setup(flash_overlay, vignette_overlay, crash_banner, saved_banner)

	bag_manager = BagManager.new()
	add_child(bag_manager)
	var job = GameManager.selected_job
	if job == null:
		job = load("res://resources/jobs/knight.tres")

	if GameManager.current_round == 1:
		GameManager.init_run_stats(job)
	player_current_hp = GameManager.player_current_hp

	if GameManager.full_bag.is_empty():
		for entry in job.starting_bag:
			for i in entry.count:
				GameManager.full_bag.append(entry.token)
		for token in GameManager.purchased_tokens:
			GameManager.full_bag.append(token)

	for token in GameManager.full_bag:
		bag_manager.add_tokens(token, 1)

	setup_enemy()

	# Setup combat slots
	_slots = combat_slots_row.get_children()
	for i in _slots.size():
		_slots[i].setup(i)
		_slots[i].token_dropped.connect(_on_token_placed_in_slot)

	button_draw.pressed.connect(_on_button_draw_pressed)

	for btn in [button_draw, button_execute, button_next, button_back_to_menu]:
		btn.focus_mode = Control.FOCUS_NONE

	bag_inspector.setup(bag_manager)
	bag_inspector.get_node("CompactView").visible = false

	player_hp_bar.max_value = GameManager.player_max_hp
	player_hp_bar.value = player_current_hp
	update_player_hp()
	update_hud()
	button_execute.disabled = true

	MusicManager.play_game()

	relic_line.setup()
	RelicManager.relic_triggered.connect(relic_line.trigger_pulse)

	bag_info_area.mouse_entered.connect(bag_inspector.open_modal)
	bag_info_area.mouse_exited.connect(bag_inspector.close_modal)
	revealed_token_holder.drag_started.connect(_on_drag_started)

	_setup_hover(button_execute)
	update_ui()

func setup_enemy() -> void:
	var stats = GameManager.get_current_stats()

	current_enemy = Enemy.new()
	add_child(current_enemy)

	var enemy_data = EnemyResource.new()
	enemy_data.enemy_name = "The Entity"
	enemy_data.max_hp = stats.hp
	enemy_data.base_damage = stats.atk

	current_enemy.setup(enemy_data)
	current_enemy.hp_changed.connect(_on_enemy_hp_changed)
	current_enemy.intention_changed.connect(_on_enemy_intention_changed)
	current_enemy.enemy_died.connect(_on_enemy_died)

	var display_ante = GameManager.get_current_ante() - 1
	var display_round = GameManager.get_round_in_ante()
	label_enemy_name.text = "%d.%d — %s" % [display_ante, display_round, GameManager.get_depth_name().to_upper()]
	if GameManager.is_boss_round():
		label_enemy_name.text += " ★ BOSS"
	enemy_hp_bar.max_value = stats.hp
	enemy_hp_bar.value = stats.hp
	label_enemy_hp.text = "%d/%d" % [stats.hp, stats.hp]
	label_intention_type.text = "ATTACK"
	label_enemy_intention.text = "◆ %d" % stats.atk

	if GameManager.is_boss_round():
		blob_bg.material.set_shader_parameter("color", Color(0.85, 0.1, 0.15, 1.0))
		var white := Color.WHITE
		label_enemy_name.add_theme_color_override("font_color", white)
		label_enemy_hp.add_theme_color_override("font_color", white)
		label_intention_type.add_theme_color_override("font_color", white)
		label_enemy_intention.add_theme_color_override("font_color", white)
		label_turns.add_theme_color_override("font_color", white)
		label_turns_title.add_theme_color_override("font_color", white)
		label_gold.add_theme_color_override("font_color", white)
		label_salt_title.add_theme_color_override("font_color", white)
		salt_icon.modulate = white
		enemy_hp_bar.add_theme_stylebox_override("fill", _make_white_stylebox())

var _btn_origins := {}

func _setup_hover(btn: Button) -> void:
	btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))

func _on_btn_hover(btn: Button, hovering: bool) -> void:
	if not _btn_origins.has(btn):
		_btn_origins[btn] = btn.position
	var target = _btn_origins[btn] + Vector2(0, -6) if hovering else _btn_origins[btn]
	var t = create_tween()
	t.tween_property(btn, "position", target, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_drag_started(token: TokenResource, origin_pos: Vector2) -> void:
	_drag_token = token
	_dragging = true
	_prev_mouse_pos = get_global_mouse_position()
	_drag_velocity = Vector2.ZERO

	_drag_card = token_card_scene.instantiate()
	add_child(_drag_card)
	_drag_card.setup(token)
	_drag_card.z_index = 100
	_drag_card.z_as_relative = false
	_drag_card.pivot_offset = Vector2(70, 70)
	_drag_card.global_position = origin_pos
	_drag_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	revealed_token_holder.set_card_alpha(0.25)

	var t = _drag_card.create_tween()
	t.tween_property(_drag_card, "scale", Vector2(1.08, 1.08), 0.12)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	if not _dragging or _drag_card == null:
		return
	var mouse_pos := get_global_mouse_position()
	var target := mouse_pos - Vector2(70, 70)

	_drag_card.global_position = _drag_card.global_position.lerp(target, min(1.0, 18.0 * delta))

	var frame_vel: Vector2 = (mouse_pos - _prev_mouse_pos) / max(delta, 0.001)
	_drag_velocity = _drag_velocity.lerp(frame_vel, 0.25)
	_prev_mouse_pos = mouse_pos

	var target_rot: float = clamp(_drag_velocity.x * 0.0012, -0.22, 0.22)
	_drag_card.rotation = lerp(_drag_card.rotation, target_rot, 12.0 * delta)

func _end_drag() -> void:
	_dragging = false
	if _drag_card == null:
		return

	var card_center := _drag_card.global_position + Vector2(70, 70)
	var drop_slot: Node = null
	for slot in _slots:
		if slot.is_empty():
			var slot_center: Vector2 = slot.global_position + Vector2(70, 70)
			if card_center.distance_to(slot_center) < 90.0:
				drop_slot = slot
				break

	var card := _drag_card
	_drag_card = null

	if drop_slot != null:
		var t = card.create_tween()
		t.set_parallel(true)
		t.tween_property(card, "global_position", drop_slot.global_position, 0.12)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(card, "rotation", 0.0, 0.12)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)
		await t.finished
		card.queue_free()
		revealed_token_holder.clear()
		drop_slot.place_token(_drag_token)
		var dropped_token := _drag_token
		_drag_token = null
		await _on_token_placed_in_slot(drop_slot.slot_index, dropped_token)
	else:
		# Return to holder
		var t = card.create_tween()
		t.set_parallel(true)
		t.tween_property(card, "global_position", revealed_token_holder.global_position, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(card, "rotation", 0.0, 0.2)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
		await t.finished
		card.queue_free()
		revealed_token_holder.set_card_alpha(1.0)
		_drag_token = null

func _on_button_draw_pressed() -> void:
	var token = bag_manager.draw_token()
	if token == null:
		return

	if token.token_type == TokenResource.TokenType.HAZARD:
		vfx.trigger_hazard_flash()
		var bonus_dmg := RelicManager.trigger_hazard_drawn()
		if bonus_dmg > 0 and current_enemy != null:
			current_enemy.take_damage(bonus_dmg)
		# Auto-place on a random free slot
		var free_slots: Array[Node] = []
		for slot in _slots:
			if slot.is_empty():
				free_slots.append(slot)
		if free_slots.is_empty():
			# No free slot — treat as revealed for manual handling
			revealed_token_holder.reveal(token)
			button_draw.disabled = true
		else:
			var target_slot = free_slots[randi() % free_slots.size()]
			target_slot.place_token(token)
			await _on_token_placed_in_slot(target_slot.slot_index, token)
			return
	else:
		revealed_token_holder.reveal(token)
		button_draw.disabled = true

	update_ui()

func _on_token_placed_in_slot(_slot_index: int, _token: TokenResource) -> void:
	revealed_token_holder.clear()

	var hazard_count := _count_hazards_in_slots()
	if hazard_count >= 2:
		await _handle_crash()
	else:
		button_draw.disabled = false
		update_ui()

func _handle_crash() -> void:
	print("💥 CRASH!")
	var placed_count := _get_slot_cards().size()
	var protected := RelicManager.trigger_before_crash(placed_count, _count_hazards_in_slots())
	button_draw.disabled = true
	button_execute.disabled = true
	if protected:
		await vfx.trigger_saved_effect()
	else:
		await vfx.trigger_crash_effect()
	button_draw.disabled = false
	button_execute.disabled = false

	var cards = _get_slot_cards()
	var result = TokenEffectResolver.resolve(cards) if not cards.is_empty() else null
	var crash_damage := roundi(current_enemy.current_damage * result.damage_multiplier) if result != null else current_enemy.current_damage
	var incoming_damage := 0 if protected else crash_damage
	player_current_hp -= incoming_damage
	player_current_hp = max(player_current_hp, 0)
	update_player_hp()

	if player_current_hp <= 0:
		_handle_player_death()
		return

	current_enemy.prepare_next_intention()

	for slot in _slots:
		var t = slot.take_token()
		if t:
			bag_manager.bag.append(t)

	bag_manager.shuffle()
	update_ui()
	print("=== FIN DU TOUR (CRASH) ===")

func _on_button_execute_pressed() -> void:
	RelicManager.reset_combat_states()
	turns_played += 1
	GameManager.turns_played_last_combat = turns_played
	print("=== PHASE D'EXÉCUTION ===")

	# Return any unplaced revealed token to bag
	var unplaced: TokenResource = revealed_token_holder.get_token()
	if unplaced != null:
		bag_manager.bag.append(unplaced)
		revealed_token_holder.clear()

	var cards = _get_slot_cards()
	if cards.is_empty():
		update_ui()
		return

	# Collect tokens before clearing slots
	var tokens_to_return: Array[TokenResource] = []
	for slot in _slots:
		var t = slot.get_token()
		if t:
			tokens_to_return.append(t)

	var result = TokenEffectResolver.resolve(cards)

	var hazard_count := _count_hazards_in_slots()
	var context := {
		"hazard_count": hazard_count,
		"gold": GameManager.gold,
	}
	context = RelicManager.trigger_execute(context)
	GameManager.gold = context["gold"]
	update_hud()

	print("Joueur inflige %d dégâts à l'ennemi" % result.total_attack)
	current_enemy.take_damage(result.total_attack)

	if current_enemy.current_hp > 0:
		var base_damage = current_enemy.current_damage
		var modified_damage = roundi(base_damage * result.damage_multiplier)
		var incoming_damage = max(0, modified_damage - result.total_defense)

		print("Ennemi attaque pour %d (défense: %d) = %d dégâts reçus" % [modified_damage, result.total_defense, incoming_damage])

		player_current_hp -= incoming_damage
		player_current_hp = max(player_current_hp, 0)
		update_player_hp()

		if player_current_hp <= 0:
			_handle_player_death()
			return

		current_enemy.prepare_next_intention()

	# Clear slots and return tokens to bag
	for slot in _slots:
		slot.take_token()
	for t in tokens_to_return:
		bag_manager.bag.append(t)

	bag_manager.shuffle()
	print("=== FIN DU TOUR ===")
	update_ui()

func _handle_player_death() -> void:
	print("💀 DÉFAITE!")
	button_draw.disabled = true
	button_execute.disabled = true
	button_next.visible = false
	button_back_to_menu.visible = true
	button_back_to_menu.disabled = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _dragging:
			get_viewport().set_input_as_handled()
			_end_drag()

	if event is InputEventKey and not event.echo:
		match event.keycode:
			KEY_SPACE:
				get_viewport().set_input_as_handled()
				if event.pressed and not button_draw.disabled:
					_on_button_draw_pressed()
			KEY_ENTER, KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				if event.pressed and not button_execute.disabled:
					_on_button_execute_pressed()
			KEY_TAB:
				get_viewport().set_input_as_handled()
				if event.pressed:
					bag_inspector.open_modal()
				else:
					bag_inspector.close_modal()

func update_ui() -> void:
	update_combat_line_totals()
	update_draw_pile()
	bag_inspector.refresh()
	update_hud()
	var any_filled = _slots.any(func(s): return not s.is_empty())
	button_execute.disabled = not any_filled

func update_draw_pile() -> void:
	var bag_size: int = bag_manager.bag.size()
	draw_count_label.text = "%d" % bag_size

	# Rebuild stacked pile circles below DRAW button
	for child in draw_pile_stack.get_children():
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
		draw_pile_stack.add_child(circle)

	for child in type_breakdown_box.get_children():
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
		type_breakdown_box.add_child(row)

func update_hud() -> void:
	label_turns.text = "%d" % turns_played
	label_gold.text = "%d" % GameManager.gold
	label_base_damage.text = "%d" % GameManager.base_damage
	label_base_defense.text = "%d" % GameManager.base_defense

func update_player_hp() -> void:
	GameManager.player_current_hp = player_current_hp
	label_player_hp.text = "%d/%d" % [player_current_hp, GameManager.player_max_hp]
	var t = create_tween()
	t.tween_property(player_hp_bar, "value", player_current_hp, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func update_combat_line_totals() -> void:
	var cards = _get_slot_cards()

	if cards.is_empty():
		_update_hazard_wave(0)
		damage_preview_box.visible = false
		defense_preview_box.visible = false
		label_intention_type.text = "ATTACK"
		label_enemy_intention.text = "◆ %d" % current_enemy.current_damage
		label_enemy_intention.add_theme_color_override("font_color", _intention_color())
		label_intention_type.add_theme_color_override("font_color", _intention_color())
		label_defense_preview.add_theme_color_override("font_color", Color(0.24, 0.4, 1, 1))
		# Reset effect states
		for slot in _slots:
			if slot.get_card() != null:
				slot.get_card().set_effect_state("none")
		return

	var result = TokenEffectResolver.resolve(cards)

	var last_index = cards.size() - 1
	for i in range(cards.size()):
		var card = cards[i]
		var effect = card.token_data.effect
		if effect == TokenResource.TokenEffect.PROVOCATION:
			card.set_effect_state("superior" if i == 0 else "basic")
		elif effect == TokenResource.TokenEffect.RAMPART:
			card.set_effect_state("superior" if i == last_index else "basic")
		else:
			card.set_effect_state("none")

	var attack_count = 0
	for card in cards:
		if card.token_data.token_type == TokenResource.TokenType.ATTACK:
			attack_count += 1
	damage_preview_box.visible = attack_count > 0
	label_damage_preview.text = "%d" % result.total_attack

	defense_preview_box.visible = result.total_defense > 0
	if result.rampart_active:
		label_defense_preview.text = "%d (x2)" % (result.total_defense / 2)
		label_defense_preview.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0, 1))
	else:
		label_defense_preview.text = "%d" % result.total_defense
		label_defense_preview.add_theme_color_override("font_color", Color(0.24, 0.4, 1, 1))

	var modified_damage = roundi(current_enemy.current_damage * result.damage_multiplier)
	if result.damage_multiplier < 1.0:
		label_intention_type.text = "ATTACK (REDUCED)"
		label_enemy_intention.text = "◆ %d" % modified_damage
		label_enemy_intention.add_theme_color_override("font_color", Color(0.1, 0.55, 0.1, 1))
		label_intention_type.add_theme_color_override("font_color", Color(0.1, 0.55, 0.1, 1))
	else:
		label_intention_type.text = "ATTACK"
		label_enemy_intention.text = "◆ %d" % current_enemy.current_damage
		label_enemy_intention.add_theme_color_override("font_color", _intention_color())
		label_intention_type.add_theme_color_override("font_color", _intention_color())

	var hazard_count := _count_hazards_in_slots()
	_update_hazard_wave(hazard_count)

func _get_slot_cards() -> Array:
	var cards := []
	for slot in _slots:
		if not slot.is_empty() and slot.get_card() != null:
			cards.append(slot.get_card())
	return cards

func _count_hazards_in_slots() -> int:
	var count := 0
	for slot in _slots:
		if not slot.is_empty() and slot.get_token().token_type == TokenResource.TokenType.HAZARD:
			count += 1
	return count

func _update_hazard_wave(hazard_count: int) -> void:
	vfx.update_vignette(hazard_count)

func _intention_color() -> Color:
	return Color.WHITE if GameManager.is_boss_round() else Color.BLACK

func _make_white_stylebox() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.WHITE
	return s

func _on_enemy_hp_changed(new_hp: int, max_hp: int) -> void:
	label_enemy_hp.text = "%d/%d" % [new_hp, max_hp]
	var t = create_tween()
	t.tween_property(enemy_hp_bar, "value", new_hp, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_enemy_intention_changed(_intention_type: String, damage: int) -> void:
	label_enemy_intention.text = "◆ %d" % damage

func _on_enemy_died() -> void:
	print("=== COMBAT TERMINÉ : VICTOIRE ===")
	GameManager.turns_played_last_combat = turns_played
	button_draw.disabled = true
	button_execute.disabled = true
	await get_tree().create_timer(1.0).timeout
	if GameManager.is_boss_round():
		get_tree().change_scene_to_file("res://sacrifice_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://reward_screen.tscn")

func _on_button_next_pressed() -> void:
	print("=== ROUND SUIVANT ===")
	GameManager.advance_round()
	get_tree().reload_current_scene()

func _on_button_back_to_menu_pressed() -> void:
	GameManager.reset_run()
	MusicManager.stop(0.8)
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://main_menu.tscn")
