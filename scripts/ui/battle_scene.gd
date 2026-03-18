extends Control

# Enemy zone
@onready var blob_bg = $EnemyZone/BlobBG
@onready var label_enemy_name = $EnemyZone/EnemyContent/NameRow/LabelEnemyName
@onready var label_enemy_hp = $EnemyZone/EnemyContent/NameRow/LabelEnemyHP
@onready var enemy_hp_bar = $EnemyZone/EnemyContent/EnemyHPBar
@onready var label_intention_type = $EnemyZone/IntentionBox/LabelIntentionType
@onready var label_enemy_intention = $EnemyZone/IntentionBox/LabelEnemyIntention

# HUD
@onready var label_turns = $PlayerHUDRow/TurnSection/LabelTurns
@onready var label_turns_title = $PlayerHUDRow/TurnSection/LabelTurnsTitle
@onready var label_gold = $PlayerHUDRow/SaltSection/LabelGold
@onready var label_salt_title = $PlayerHUDRow/SaltSection/LabelSaltTitle

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

# Pressure row
@onready var label_pressure_value = $PlayerHUDRow/PressureSection/LabelPressureValue
@onready var label_turn_atk = $PlayerHUDRow/ATKSection/LabelTurnATK
@onready var label_turn_def = $PlayerHUDRow/DEFSection/LabelTurnDEF

# Player bottom bar
@onready var relic_line = $PlayerBottomBar/CenterSection/RelicLine
@onready var player_hp_bar = $PlayerBottomBar/CenterSection/PlayerHPBar
@onready var label_player_hp = $PlayerBottomBar/CenterSection/LabelPlayerHP
@onready var label_base_damage = $PlayerBottomBar/LeftStatSection/TopRow/LabelBaseDamage
@onready var label_base_defense = $PlayerBottomBar/RightStatSection/TopRow/LabelBaseDefense
@onready var label_dmg_title = $PlayerBottomBar/LeftStatSection/LabelDmgTitle
@onready var label_def_title = $PlayerBottomBar/RightStatSection/LabelDefTitle

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
var current_pressure: float = 1.0
var _slots: Array[Node] = []

var drag_controller: DragController
var hud: BattleHUD

func _ready():
	vfx = BattleVFX.new()
	add_child(vfx)
	vfx.setup(flash_overlay, vignette_overlay, crash_banner, saved_banner, self)

	drag_controller = DragController.new()
	add_child(drag_controller)

	hud = BattleHUD.new()
	add_child(hud)
	hud.setup(self)

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
		_slots[i].slot_clicked.connect(_on_slot_clicked)

	drag_controller.setup(_slots, revealed_token_holder, token_card_scene, self)
	drag_controller.drag_dropped.connect(_on_token_placed_in_slot)

	button_draw.pressed.connect(_on_button_draw_pressed)

	for btn in [button_draw, button_execute, button_next, button_back_to_menu]:
		btn.focus_mode = Control.FOCUS_NONE

	bag_inspector.setup(bag_manager)
	bag_inspector.get_node("CompactView").visible = false

	player_hp_bar.max_value = GameManager.player_max_hp
	player_hp_bar.value = player_current_hp
	hud.update_player_hp()
	hud.update_hud()
	button_execute.disabled = true

	MusicManager.play_game()

	relic_line.setup()
	RelicManager.relic_triggered.connect(relic_line.trigger_pulse)

	bag_info_area.mouse_entered.connect(bag_inspector.open_modal)
	bag_info_area.mouse_exited.connect(bag_inspector.close_modal)
	revealed_token_holder.drag_started.connect(drag_controller.start_drag)
	revealed_token_holder.clear()

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
	current_enemy.hp_changed.connect(hud.on_enemy_hp_changed)
	current_enemy.intention_changed.connect(hud.on_enemy_intention_changed)
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
		enemy_hp_bar.add_theme_stylebox_override("fill", hud.make_white_stylebox())

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

func _on_button_draw_pressed() -> void:
	if _count_hazards_in_slots() > 0:
		current_pressure += GameManager.pressure_increment

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

func _on_slot_clicked(slot_index: int) -> void:
	var token: TokenResource = revealed_token_holder.get_token()
	if token == null or drag_controller.is_dragging():
		return
	revealed_token_holder.clear()
	_slots[slot_index].place_token(token)
	await _on_token_placed_in_slot(slot_index, token)

func _on_token_placed_in_slot(_slot_index: int, _token: TokenResource) -> void:
	revealed_token_holder.clear()

	var hazard_count := _count_hazards_in_slots()
	if hazard_count >= 2:
		vfx.trigger_screen_shake()
		await get_tree().create_timer(0.5).timeout
		await _handle_crash()
	else:
		update_ui()

func _handle_crash() -> void:
	print("💥 CRASH!")
	current_pressure += GameManager.pressure_increment * 2.0
	var placed_count := _get_slot_cards().size()
	var protected := RelicManager.trigger_before_crash(placed_count, _count_hazards_in_slots())
	button_draw.disabled = true
	button_execute.disabled = true
	TooltipManager.set_enabled(false)
	if protected:
		await vfx.trigger_saved_effect()
	else:
		await vfx.trigger_crash_effect()
	TooltipManager.set_enabled(true)
	button_draw.disabled = false
	button_execute.disabled = false

	var cards = _get_slot_cards()
	var result = TokenEffectResolver.resolve(cards) if not cards.is_empty() else null
	var crash_damage := roundi(current_enemy.current_damage * result.damage_multiplier) if result != null else current_enemy.current_damage
	var incoming_damage := 0 if protected else crash_damage
	player_current_hp -= incoming_damage
	player_current_hp = max(player_current_hp, 0)
	hud.update_player_hp()

	if player_current_hp <= 0:
		_handle_player_death()
		return

	current_enemy.prepare_next_intention()

	await _animate_tokens_to_draw_area()

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
		"total_attack": result.total_attack,
		"total_defense": result.total_defense,
		"pressure": current_pressure,
	}
	# Echoes trigger left to right, can modify ATK, DEF, or Pressure
	context = RelicManager.trigger_execute(context)
	GameManager.gold = context["gold"]
	hud.update_hud()

	# Apply Pressure to both ATK and DEF simultaneously
	var final_attack := roundi(context.get("total_attack", result.total_attack) * context.get("pressure", current_pressure))
	var final_defense := roundi(context.get("total_defense", result.total_defense) * context.get("pressure", current_pressure))

	# Animate pressure multiplication visually — ATK first, then DEF
	button_draw.disabled = true
	button_execute.disabled = true
	var atk_color := Color(0.91, 0.16, 0.29, 1) if final_attack > 0 else Color(1, 1, 1, 1)
	var def_color := Color(0.24, 0.4, 1, 1) if final_defense > 0 else Color(1, 1, 1, 1)
	await hud.animate_pressure_on_stat(label_turn_atk, "%d" % final_attack, atk_color)
	await get_tree().create_timer(0.15).timeout
	await hud.animate_pressure_on_stat(label_turn_def, "%d" % final_defense, def_color)
	await get_tree().create_timer(0.2).timeout

	# Player hits enemy — wait for HP bar to finish
	print("Joueur inflige %d dégâts à l'ennemi (pression: %.1f)" % [final_attack, context.get("pressure", current_pressure)])
	current_enemy.take_damage(final_attack)
	await get_tree().create_timer(0.7).timeout

	if current_enemy.current_hp <= 0:
		for slot in _slots:
			slot.take_token()
		for t in tokens_to_return:
			bag_manager.bag.append(t)
		bag_manager.shuffle()
		return

	# Enemy hits player — wait for HP bar to finish
	var base_damage = current_enemy.current_damage
	var modified_damage = roundi(base_damage * result.damage_multiplier)
	var incoming_damage = max(0, modified_damage - final_defense)
	print("Ennemi attaque pour %d (défense: %d) = %d dégâts reçus" % [modified_damage, final_defense, incoming_damage])
	player_current_hp -= incoming_damage
	player_current_hp = max(player_current_hp, 0)
	hud.update_player_hp()
	await get_tree().create_timer(0.7).timeout

	if player_current_hp <= 0:
		_handle_player_death()
		return

	current_enemy.prepare_next_intention()

	# Pause, then animate tokens back to draw pile
	await get_tree().create_timer(0.3).timeout
	await _animate_tokens_to_draw_area()

	for slot in _slots:
		slot.take_token()
	for t in tokens_to_return:
		bag_manager.bag.append(t)

	button_draw.disabled = false
	bag_manager.shuffle()
	print("=== FIN DU TOUR ===")
	update_ui()

func _animate_tokens_to_draw_area() -> void:
	var target: Vector2 = button_draw.global_position + Vector2(70, 70)
	var flying: Array[Control] = []

	for slot in _slots:
		var gpos: Vector2 = slot.global_position
		var card: Control = slot.pop_card()
		if card == null:
			continue
		add_child(card)
		card.global_position = gpos
		card.z_index = 50
		card.z_as_relative = false
		flying.append(card)

	if flying.is_empty():
		return

	for i in flying.size():
		var card := flying[i]
		card.pivot_offset = Vector2(70, 70)
		var t = card.create_tween()
		t.set_parallel(true)
		var delay := i * 0.07
		t.tween_property(card, "global_position", target - Vector2(70, 70), 0.45)\
			.set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		t.tween_property(card, "scale", Vector2(0.25, 0.25), 0.45)\
			.set_delay(delay).set_ease(Tween.EASE_IN)
		t.tween_property(card, "modulate:a", 0.0, 0.3)\
			.set_delay(delay + 0.2)

	var total_wait := (flying.size() - 1) * 0.07 + 0.45
	await get_tree().create_timer(total_wait).timeout

	for card in flying:
		card.queue_free()

func _handle_player_death() -> void:
	print("💀 DÉFAITE!")
	current_pressure = 1.0
	button_draw.disabled = true
	button_execute.disabled = true
	button_next.visible = false
	button_back_to_menu.visible = true
	button_back_to_menu.disabled = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if drag_controller.is_dragging():
			get_viewport().set_input_as_handled()
			drag_controller.end_drag()

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
	hud.update_combat_line_totals()
	hud.update_draw_pile(bag_manager)
	bag_inspector.refresh()
	hud.update_hud()
	var any_filled = _slots.any(func(s): return not s.is_empty())
	button_execute.disabled = not any_filled
	_refresh_draw_button()

func _refresh_draw_button() -> void:
	var slots_full := _slots.all(func(s): return not s.is_empty())
	var token_pending := revealed_token_holder.get_token() != null
	button_draw.disabled = slots_full or token_pending
	var s := StyleBoxFlat.new()
	s.corner_radius_top_left = 70
	s.corner_radius_top_right = 70
	s.corner_radius_bottom_right = 70
	s.corner_radius_bottom_left = 70
	if slots_full:
		s.bg_color = Color(0.08, 0.08, 0.08, 1)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button_draw.add_theme_stylebox_override(state, s)
		button_draw.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35, 1))
		button_draw.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.35, 1))
	else:
		s.bg_color = Color(1, 1, 1, 1)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button_draw.add_theme_stylebox_override(state, s)
		button_draw.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		button_draw.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 1))

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

func _on_enemy_died() -> void:
	print("=== COMBAT TERMINÉ : VICTOIRE ===")
	GameManager.turns_played_last_combat = turns_played
	button_draw.disabled = true
	button_execute.disabled = true
	await get_tree().create_timer(1.0).timeout
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
