extends Control

const CombatSlotScene := preload("res://combat_slot.tscn")

# Enemy zone
@onready var blob_bg = $EnemyZone/BlobBG
@onready var label_enemy_name = $EnemyZone/EnemyContent/NameRow/LabelEnemyName
@onready var label_enemy_hp = $EnemyZone/EnemyContent/LabelEnemyHPCenter
@onready var enemy_hp_bar = $EnemyZone/EnemyContent/EnemyHPBar
@onready var label_intention_type = $EnemyZone/IntentionBox/LabelIntentionType
@onready var label_enemy_intention = $EnemyZone/IntentionBox/LabelEnemyIntention

# HUD (forwarded from RunHUD in _ready)
var label_turns: Label
var label_turns_title: Label
var label_gold: Label

# Combat slots + controls
@onready var combat_slots_row = $CombatSlotsRow
@onready var button_execute = $ButtonExecute
@onready var revealed_token_holder = $DrawArea/RevealedTokenHolder

# Draw area
@onready var draw_area = $DrawArea
@onready var button_draw = $DrawArea/ButtonDraw
@onready var draw_pile_stack = $DrawArea/DrawPileStack
var bag_info_area: Control
var draw_count_label: Label
var type_breakdown_box: VBoxContainer

# Pressure row
@onready var label_pressure_value = $PlayerHUDRow/PressureSection/LabelPressureValue
@onready var label_turn_atk = $PlayerHUDRow/ATKSection/ATKBox/LabelTurnATK
@onready var label_turn_def = $PlayerHUDRow/DEFSection/DEFBox/LabelTurnDEF
@onready var atk_box = $PlayerHUDRow/ATKSection/ATKBox
@onready var def_box = $PlayerHUDRow/DEFSection/DEFBox

# Player bottom bar (forwarded from RunHUD in _ready)
var relic_line: Node
var player_hp_bar: ProgressBar
var label_player_hp: Label
var label_base_damage: Label
var label_base_defense: Label

# VFX
@onready var flash_overlay = $FlashOverlay
@onready var vignette_overlay = $VignetteOverlay
@onready var crash_banner = $CrashBanner
@onready var saved_banner = $SavedBanner
var vfx: BattleVFX

# Nav
@onready var button_next = $ButtonNext
@onready var button_back_to_menu = $ButtonBackToMenu

# State
var token_card_scene = preload("res://token_card.tscn")
var bag_manager = BagManager
var current_enemy: Enemy
var player_current_hp: int
var turns_played: int = 0
var current_pressure: float = 1.0  # set from pending_pressure_boost at zone start
var _slots: Array[Node] = []

var drag_controller: DragController
var hud: BattleHUD
var token_vfx: TokenVFX
var hud_vfx: HudVFX
var _death_blow_active: bool = false

func _ready():
	RunHUD.visible = true
	RunHUD.set_info_color(Color.BLACK)
	# Forward RunHUD node refs so BattleHUD and this script can access via local var names
	label_turns = RunHUD.label_turns
	label_turns_title = RunHUD.label_turns_title
	label_gold = RunHUD.label_gold
	relic_line = RunHUD.relic_line
	player_hp_bar = RunHUD.player_hp_bar
	label_player_hp = RunHUD.label_player_hp
	label_base_damage = RunHUD.label_base_damage
	label_base_defense = RunHUD.label_base_defense
	draw_count_label = RunHUD.draw_count_label
	type_breakdown_box = RunHUD.type_breakdown_box
	bag_info_area = RunHUD.bag_info_area

	vfx = BattleVFX.new()
	add_child(vfx)
	vfx.setup(flash_overlay, vignette_overlay, crash_banner, saved_banner, self)

	drag_controller = DragController.new()
	add_child(drag_controller)

	token_vfx = TokenVFX.new()
	add_child(token_vfx)
	token_vfx.setup(self)

	hud_vfx = HudVFX.new()
	add_child(hud_vfx)
	hud_vfx.setup(self)

	hud = BattleHUD.new()
	add_child(hud)
	hud.setup(self)

	bag_manager = BagManager.new()
	add_child(bag_manager)
	var job = GameManager.selected_job
	if job == null:
		job = load("res://resources/jobs/knight.tres")

	current_pressure = GameManager.base_pressure_floor + GameManager.pending_pressure_boost
	GameManager.pending_pressure_boost = 0.0

	if GameManager.current_zone == 1:
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
	for child in combat_slots_row.get_children():
		child.queue_free()
	for i in GameManager.slot_count:
		var slot = CombatSlotScene.instantiate()
		combat_slots_row.add_child(slot)
		slot.setup(i)
		slot.token_dropped.connect(_on_token_placed_in_slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		_slots.append(slot)

	drag_controller.setup(_slots, revealed_token_holder, token_card_scene, self)
	drag_controller.drag_dropped.connect(_on_token_placed_in_slot)

	button_draw.pressed.connect(_on_button_draw_pressed)

	for btn in [button_draw, button_execute, button_next, button_back_to_menu]:
		btn.focus_mode = Control.FOCUS_NONE

	RunHUD.bag_inspector.setup(bag_manager)

	player_hp_bar.max_value = GameManager.player_max_hp
	player_hp_bar.value = player_current_hp
	hud.update_player_hp()
	hud.update_hud()
	button_execute.disabled = true

	MusicManager.play_game()

	relic_line.refresh()
	if not RelicManager.relic_triggered.is_connected(relic_line.trigger_pulse):
		RelicManager.relic_triggered.connect(relic_line.trigger_pulse)


	revealed_token_holder.drag_started.connect(drag_controller.start_drag)
	revealed_token_holder.clear()

	_setup_hover(button_execute)
	update_ui()

func setup_enemy() -> void:
	var stats = GameManager.get_current_stats()
	if stats == null:
		push_error("No stats defined for zone %d" % GameManager.current_zone)
		return

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
	var display_zone = GameManager.get_zone_in_ante()
	label_turns_title.text = GameManager.get_depth_name().to_upper()
	label_turns.text = "%d.%d" % [display_ante, display_zone]
	if GameManager.is_boss_zone():
		label_turns_title.text += " ★ BOSS"
	enemy_hp_bar.max_value = stats.hp
	enemy_hp_bar.value = stats.hp
	label_enemy_hp.text = "%d/%d" % [stats.hp, stats.hp]
	label_enemy_intention.text = "ENTITY ATTACK ◆ %d" % stats.atk

	if GameManager.is_boss_zone():
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
		label_pressure_value.text = "x%.2f" % current_pressure
		hud_vfx.animate_pressure_label(label_pressure_value)

	var token = bag_manager.draw_token()
	if token == null:
		return

	if token.token_type == TokenResource.TokenType.HAZARD:
		SFXManager.play("hazard")
		vfx.trigger_hazard_flash()
		vfx.trigger_screen_shake(5.0, 0.25)
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
	TooltipManager.suppress_briefly()
	_slots[slot_index].place_token(token)
	await _on_token_placed_in_slot(slot_index, token)

func _on_token_placed_in_slot(_slot_index: int, _token: TokenResource) -> void:
	if _token.placement_swap:
		_do_swing_swap(_slot_index)
	revealed_token_holder.clear()
	SFXManager.play("draw")

	var hazard_count := _count_hazards_in_slots()
	if hazard_count >= 2:
		vfx.trigger_screen_shake(18.0, 0.55)
		await get_tree().create_timer(0.5).timeout
		await _handle_crash()
	else:
		update_ui()

func _do_swing_swap(slot_index: int) -> void:
	var total := _slots.size()
	var neighbor_index: int
	if slot_index == 0:
		neighbor_index = 1
	elif slot_index == total - 1:
		neighbor_index = total - 2
	else:
		neighbor_index = slot_index + (1 if randi() % 2 == 0 else -1)
	var neighbor_slot = _slots[neighbor_index]
	if neighbor_slot.is_empty():
		return
	var neighbor_token: TokenResource = neighbor_slot.take_token()
	var swing_token: TokenResource = _slots[slot_index].take_token()
	_slots[slot_index].place_token(neighbor_token)
	_slots[neighbor_index].place_token(swing_token)

func _handle_crash() -> void:
	print("💥 CRASH!")
	var placed_count := _get_slot_cards().size()
	var protected := RelicManager.trigger_before_crash(placed_count, _count_hazards_in_slots())
	button_draw.disabled = true
	button_execute.disabled = true
	TooltipManager.set_enabled(false)
	RunHUD.visible = false
	if protected:
		SFXManager.play("saved")
		await vfx.trigger_saved_effect()
	else:
		SFXManager.play("crash")
		await vfx.trigger_crash_effect()
	TooltipManager.set_enabled(true)
	RunHUD.visible = true
	button_draw.disabled = false
	button_execute.disabled = false

	var cards = _get_slot_cards()
	var result = TokenEffectResolver.resolve(cards, _slots.size()) if not cards.is_empty() else null
	var crash_damage := roundi(current_enemy.current_damage * result.damage_multiplier) if result != null else current_enemy.current_damage
	var crash_def_count: int = cards.filter(func(c): return c.token_data.token_type == TokenResource.TokenType.DEFENSE).size()
	var crash_context: Dictionary = {"damage": crash_damage, "gold": GameManager.gold, "def_count": crash_def_count}
	crash_context = RelicManager.trigger_crash(crash_context)
	crash_damage = crash_context.get("damage", crash_damage)
	var crash_gold_diff: int = crash_context.get("gold", GameManager.gold) - GameManager.gold
	if crash_gold_diff != 0:
		GameManager.add_gold(crash_gold_diff)
	var incoming_damage := 0 if protected else crash_damage
	if not protected:
		GameManager.total_crashes += 1
	player_current_hp -= incoming_damage
	player_current_hp = max(player_current_hp, 0)
	hud.update_player_hp()

	if player_current_hp <= 0:
		_handle_player_death()
		return

	current_enemy.prepare_next_intention()

	for slot in _slots:
		slot.set_effect_state(false)
		slot.set_streak_active(false)

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

	button_draw.disabled = true
	button_execute.disabled = true

	var result = TokenEffectResolver.resolve(cards, _slots.size())

	# Grey out inactive placement tokens
	var filled_slots: Array = []
	for slot in _slots:
		if not slot.is_empty() and slot.get_card() != null:
			filled_slots.append(slot)
	for i in result.inactive_slots:
		if i < filled_slots.size():
			var c = filled_slots[i].get_card()
			if c:
				c.set_inactive(true)
				filled_slots[i].set_effect_state(false)

	# Initialize running totals and display them
	var running_atk: int = result.total_attack
	var running_def: int = result.total_defense
	var running_pressure: float = current_pressure
	label_turn_atk.parse_bbcode("[center][color=#ffffff]%d[/color][/center]" % running_atk)
	label_turn_def.parse_bbcode("[center][color=#ffffff]%d[/color][/center]" % running_def)
	label_pressure_value.text = "x%.2f" % running_pressure

	# === PHASE A: Slot-by-slot resolution (left to right) ===
	var filled_idx := 0
	var slot_context: Dictionary = {
		"total_attack": running_atk,
		"total_defense": running_def,
		"pressure": running_pressure,
		"gold": GameManager.gold,
	}
	var running_dmg_mult: float = 1.0

	for slot in _slots:
		if slot.is_empty():
			# Empty slot — fire on_empty_slot for each relic
			for i in RelicManager.relics.size():
				var atk_before: int = slot_context.get("total_attack", 0)
				var def_before: int = slot_context.get("total_defense", 0)
				var psr_before: float = slot_context.get("pressure", 1.0)
				slot_context = RelicManager.relics[i].on_empty_slot(slot_context)

				var atk_d: bool = slot_context.get("total_attack", 0) != atk_before
				var def_d: bool = slot_context.get("total_defense", 0) != def_before
				var psr_d: bool = slot_context.get("pressure", 1.0) != psr_before

				if atk_d or def_d or psr_d:
					RelicManager.relic_triggered.emit(i)
					var card_center: Vector2 = RunHUD.relic_line.get_card_center(i)
					if atk_d:
						var diff: int = slot_context.get("total_attack", 0) - atk_before
						hud_vfx.floating_atk(card_center, diff)
						label_turn_atk.parse_bbcode("[center][color=#ffffff]%d[/color][/center]" % slot_context.get("total_attack", 0))
					if def_d:
						var diff: int = slot_context.get("total_defense", 0) - def_before
						hud_vfx.floating_def(card_center, diff)
						label_turn_def.parse_bbcode("[center][color=#ffffff]%d[/color][/center]" % slot_context.get("total_defense", 0))
					if psr_d:
						var diff: float = slot_context.get("pressure", 1.0) - psr_before
						hud_vfx.floating_psr(card_center, diff)
						label_pressure_value.text = "x%.2f" % slot_context.get("pressure", 1.0)
						hud_vfx.animate_pressure_label(label_pressure_value)
					await get_tree().create_timer(0.75).timeout
		else:
			var card = slot.get_card()
			var token: TokenResource = card.token_data
			var slot_center: Vector2 = slot.global_position + slot.size / 2.0

			# Skip tokens that have no visible effect in Phase A
			# (HZD tokens, lone ATK/DEF with no streak/placement bonus, etc.)
			var _has_phase_a_effect: bool = false
			for _ev in result.pressure_events:
				if _ev["slots"].has(filled_idx):
					_has_phase_a_effect = true
					break
			if not _has_phase_a_effect:
				for _ev in result.heal_events:
					if _ev["slot_index"] == filled_idx:
						_has_phase_a_effect = true
						break
			if not _has_phase_a_effect:
				for _ev in result.damage_mult_events:
					if _ev["slot_index"] == filled_idx:
						_has_phase_a_effect = true
						break
			if not _has_phase_a_effect:
				filled_idx += 1
				continue

			SFXManager.play("resolution")
			token_vfx.play_resolution(card, hud.token_type_color(token.token_type))

			# Heal event
			for ev in result.heal_events:
				if ev["slot_index"] == filled_idx:
					var heal_amount := roundi(GameManager.player_max_hp * ev["value"])
					player_current_hp = min(player_current_hp + heal_amount, GameManager.player_max_hp)
					hud.update_player_hp()
					hud_vfx.floating_text(slot_center, "+%d HP" % heal_amount, Color("#EAA21C"))

			# Per-token PRSR contribution (streaks fire once per token, not just at the last)
			for ev in result.pressure_events:
				if ev["slots"].has(filled_idx):
					var per_token: float = ev["bonus"] / float(ev["slots"].size())
					slot_context["pressure"] = slot_context.get("pressure", 1.0) + per_token
					label_pressure_value.text = "x%.2f" % slot_context.get("pressure", 1.0)
					hud_vfx.animate_pressure_label(label_pressure_value)
					hud_vfx.floating_psr(slot_center, per_token)

			# Provocation — show reduced entity ATK when this token resolves (0.5s between each step)
			var _dmult_evs: Array = result.damage_mult_events.filter(func(e): return e["slot_index"] == filled_idx)
			for _j in _dmult_evs.size():
				var _ev: Dictionary = _dmult_evs[_j]
				running_dmg_mult += _ev["value"]
				var shown_dmg: int = roundi(current_enemy.current_damage * running_dmg_mult)
				label_enemy_intention.text = "ENTITY ATTACK ◆ %d" % shown_dmg
				var pct: int = roundi(_ev["value"] * 100)
				hud_vfx.floating_text(slot_center, "%+d%% ENT ATK" % pct, Color("#EAA21C"))
				if _j < _dmult_evs.size() - 1:
					await get_tree().create_timer(0.5).timeout

			filled_idx += 1
			await get_tree().create_timer(0.75).timeout

	# Sync running values after slot loop
	running_atk = slot_context.get("total_attack", running_atk)
	running_def = slot_context.get("total_defense", running_def)
	running_pressure = slot_context.get("pressure", running_pressure)
	current_pressure = running_pressure
	GameManager.gold = slot_context.get("gold", GameManager.gold)

	# === PHASE B: Remaining echoes (non-slot-specific) ===
	var hazard_count := _count_hazards_in_slots()
	var empty_slot_count: int = _slots.filter(func(s): return s.is_empty()).size()
	var bag_hazard_count: int = GameManager.full_bag.filter(func(t): return t.token_type == TokenResource.TokenType.HAZARD).size()
	var slot_tokens: Array = _get_slot_cards().map(func(c): return c.token_data)
	var atk_count: int = slot_tokens.filter(func(t): return t.token_type == TokenResource.TokenType.ATTACK).size()
	var def_count: int = slot_tokens.filter(func(t): return t.token_type == TokenResource.TokenType.DEFENSE).size()
	var has_other_type: bool = slot_tokens.any(func(t): return t.token_type != TokenResource.TokenType.ATTACK and t.token_type != TokenResource.TokenType.DEFENSE)
	var context: Dictionary = {
		"hazard_count": hazard_count,
		"empty_slot_count": empty_slot_count,
		"bag_hazard_count": bag_hazard_count,
		"atk_count": atk_count,
		"def_count": def_count,
		"has_other_type": has_other_type,
		"streak_count": result.streak_count,
		"gold": GameManager.gold,
		"total_attack": running_atk,
		"total_defense": running_def,
		"pressure": current_pressure,
	}

	for i in RelicManager.relics.size():
		var gold_before: int = context.get("gold", 0)
		var pressure_before: float = context.get("pressure", current_pressure)
		var atk_before: int = context.get("total_attack", 0)
		var def_before: int = context.get("total_defense", 0)
		context = RelicManager.trigger_execute_single(i, context)

		var gold_changed: bool = context.get("gold", 0) != gold_before
		var pressure_changed: bool = context.get("pressure", current_pressure) != pressure_before
		var atk_changed: bool = context.get("total_attack", 0) != atk_before
		var def_changed: bool = context.get("total_defense", 0) != def_before

		if gold_changed or pressure_changed or atk_changed or def_changed:
			var card_center: Vector2 = RunHUD.relic_line.get_card_center(i)
			if gold_changed:
				var diff: int = context.get("gold", 0) - gold_before
				GameManager.add_gold(diff)
				context["gold"] = GameManager.gold
				hud_vfx.floating_text(card_center, "+%d SALT" % diff, Color("#EAA21C"))
				hud.update_hud()
			if pressure_changed:
				current_pressure = context.get("pressure", current_pressure)
				label_pressure_value.text = "x%.2f" % current_pressure
				hud_vfx.animate_pressure_label(label_pressure_value)
				hud_vfx.floating_psr(card_center, current_pressure - pressure_before)
			if atk_changed:
				var diff: int = context.get("total_attack", 0) - atk_before
				label_turn_atk.parse_bbcode("[center][color=#ffffff]%d[/color][/center]" % context.get("total_attack", 0))
				hud_vfx.floating_atk(card_center, diff)
			if def_changed:
				var diff: int = context.get("total_defense", 0) - def_before
				label_turn_def.parse_bbcode("[center][color=#ffffff]%d[/color][/center]" % context.get("total_defense", 0))
				hud_vfx.floating_def(card_center, diff)
			await get_tree().create_timer(0.75).timeout

	GameManager.gold = context.get("gold", GameManager.gold)
	current_pressure = context.get("pressure", current_pressure)
	label_pressure_value.text = "x%.2f" % current_pressure
	hud.update_hud()

	await get_tree().create_timer(0.7).timeout

	# === PHASE C: PRSR multiplies ATK and DEF ===
	var eff_pressure: float = current_pressure
	var final_attack := roundi(context.get("total_attack", result.total_attack) * eff_pressure)
	var final_defense := roundi(context.get("total_defense", result.total_defense) * eff_pressure)
	var modified_damage: int = roundi(current_enemy.current_damage * result.damage_multiplier)
	var incoming_damage: int = max(0, modified_damage - final_defense)
	context["final_attack"] = final_attack
	context["final_defense"] = final_defense
	context["incoming_damage"] = incoming_damage
	context = RelicManager.trigger_pressure_mult(context)
	final_attack = context.get("final_attack", final_attack)
	final_defense = context.get("final_defense", final_defense)
	incoming_damage = max(0, context.get("incoming_damage", incoming_damage))
	var atk_color := Color(0.91, 0.16, 0.29, 1) if final_attack > 0 else Color(0.1, 0.1, 0.1, 1)
	var def_color := Color(0.24, 0.4, 1, 1) if final_defense > 0 else Color(0.1, 0.1, 0.1, 1)
	SFXManager.play("pressure-resolution")
	hud_vfx.animate_pressure_multiply(label_pressure_value)
	hud_vfx.animate_pressure_on_stat(label_turn_atk, "%d" % final_attack, atk_box, atk_color)
	await hud_vfx.animate_pressure_on_stat(label_turn_def, "%d" % final_defense, def_box, def_color)
	await get_tree().create_timer(0.6).timeout

	# Step 4 — ATK label strikes, entity loses HP
	await token_vfx.tilt_hard(label_turn_atk)
	if final_attack > 0:
		SFXManager.play("damage")
	current_enemy.take_damage(final_attack)
	await get_tree().create_timer(0.7).timeout

	if current_enemy.current_hp <= 0:
		for slot in _slots:
			slot.take_token()
		for t in tokens_to_return:
			bag_manager.bag.append(t)
		bag_manager.shuffle()
		# Step 7 — death blow, relics may modify damage
		var death_blow_damage := roundi(incoming_damage * 0.5)
		var db_context := {"death_blow_damage": death_blow_damage, "incoming_damage": incoming_damage}
		db_context = RelicManager.trigger_deathblow(db_context)
		death_blow_damage = db_context.get("death_blow_damage", death_blow_damage)
		if death_blow_damage > 0:
			_death_blow_active = true
			TooltipManager.set_enabled(false)
			var intention_box: Control = $EnemyZone/IntentionBox
			label_enemy_intention.text = "DEATH BLOW"
			intention_box.pivot_offset = intention_box.size / 2.0
			intention_box.rotation_degrees = -10.0
			intention_box.scale = Vector2(0.6, 0.6)
			var tween_a = create_tween().set_parallel(true)
			tween_a.tween_property(intention_box, "rotation_degrees", 0.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween_a.tween_property(intention_box, "scale", Vector2(1.0, 1.0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			await tween_a.finished
			await get_tree().create_timer(0.2).timeout
			label_enemy_intention.text = "DEATH BLOW  -%d HP" % death_blow_damage
			intention_box.rotation_degrees = 5.0
			var tween_b = create_tween()
			tween_b.tween_property(intention_box, "rotation_degrees", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			await tween_b.finished
			player_current_hp = max(0, player_current_hp - death_blow_damage)
			hud.update_player_hp()
			await get_tree().create_timer(1.0).timeout
			TooltipManager.set_enabled(true)
			if player_current_hp <= 0:
				_handle_player_death()
				return
			GameManager.last_combat_pressure = current_pressure
			get_tree().change_scene_to_file("res://reward_screen.tscn")
			return
		return

	# Step 5 — DEF label fires, entity intention updates to show remaining damage
	await token_vfx.tilt_hard(label_turn_def)
	if final_defense > 0:
		label_enemy_intention.text = "ENTITY ATTACK ◆ %d" % incoming_damage
	await get_tree().create_timer(0.5).timeout

	# Step 6 — entity intention strikes, player loses HP
	await token_vfx.tilt_hard(label_enemy_intention)
	if incoming_damage == 0:
		SFXManager.play("safe")
		var negate_bonus: int = RelicManager.trigger_defense_negate()
		if negate_bonus > 0:
			current_enemy.take_damage(negate_bonus)
	else:
		SFXManager.play("damage")
	player_current_hp -= incoming_damage
	player_current_hp = max(player_current_hp, 0)
	hud.update_player_hp()
	await get_tree().create_timer(0.7).timeout

	if player_current_hp <= 0:
		_handle_player_death()
		return

	current_enemy.prepare_next_intention()

	# Clear slot effects before animating tokens back
	for slot in _slots:
		slot.set_effect_state(false)
		slot.set_streak_active(false)

	# Pause, then animate tokens back to draw pile
	await get_tree().create_timer(0.3).timeout
	await _animate_tokens_to_draw_area()

	for slot in _slots:
		slot.take_token()
	for t in tokens_to_return:
		bag_manager.bag.append(t)

	hud_vfx.reset_stat_box(atk_box)
	hud_vfx.reset_stat_box(def_box)
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
				pass  # handled by RunHUD

func update_ui() -> void:
	hud.update_combat_line_totals()
	hud.update_draw_pile(bag_manager)
	RunHUD.bag_inspector.refresh()
	hud.update_hud()
	var any_filled = _slots.any(func(s): return not s.is_empty())
	button_execute.disabled = not any_filled
	_refresh_draw_button()

func _refresh_draw_button() -> void:
	var slots_full := _slots.all(func(s): return not s.is_empty())
	var token_pending := revealed_token_holder.get_token() != null
	button_draw.disabled = slots_full or token_pending
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 70
	style.corner_radius_top_right = 70
	style.corner_radius_bottom_right = 70
	style.corner_radius_bottom_left = 70
	if slots_full:
		style.bg_color = Color(0.08, 0.08, 0.08, 1)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button_draw.add_theme_stylebox_override(state, style)
		button_draw.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35, 1))
		button_draw.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.35, 1))
	else:
		style.bg_color = Color(1, 1, 1, 1)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button_draw.add_theme_stylebox_override(state, style)
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
	GameManager.last_combat_pressure = current_pressure
	button_draw.disabled = true
	button_execute.disabled = true
	await get_tree().create_timer(1.0).timeout
	if _death_blow_active:
		return
	get_tree().change_scene_to_file("res://reward_screen.tscn")

func _on_button_next_pressed() -> void:
	print("=== ZONE SUIVANTE ===")
	GameManager.advance_zone()
	get_tree().reload_current_scene()

func _on_button_back_to_menu_pressed() -> void:
	GameManager.reset_run()
	MusicManager.stop(0.8)
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://main_menu.tscn")
