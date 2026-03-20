class_name TokenEffectResolver
extends Node

static func resolve(cards: Array, total_slots: int = 5) -> ResolveResult:
	var result = ResolveResult.new()

	for i in cards.size():
		var card = cards[i]
		var token: TokenResource = card.token_data
		var slot_index: int = card.get_parent().slot_index
		var placement_met := _placement_met(token.placement_slot, i, slot_index, total_slots)

		# Only mark inactive if the token has no base effect (does nothing off its required slot)
		if token.placement_slot != TokenResource.SlotPosition.NONE and not placement_met \
				and token.base_target == TokenResource.EffectTarget.NONE:
			result.inactive_slots.append(i)

		# Base effect — always fires
		var card_hp := 0.0
		match token.base_target:
			TokenResource.EffectTarget.DAMAGE_MULT:
				result.damage_multiplier += token.base_value
			TokenResource.EffectTarget.HP:
				card_hp += token.base_value
			TokenResource.EffectTarget.PRESSURE:
				result.pressure_bonus += token.base_value
				result.pressure_events.append({"slots": [i], "bonus": token.base_value})

		# Placement effect — fires only at right slot
		if placement_met and token.placement_target != TokenResource.EffectTarget.NONE:
			var value := token.placement_value
			if token.placement_count_scale:
				var count := 0
				for j in cards.size():
					if j != i and cards[j].token_data.token_type == token.placement_count_type:
						count += 1
				value *= count
			match token.placement_target:
				TokenResource.EffectTarget.DAMAGE_MULT:
					result.damage_multiplier += value
					if not result.placement_active_slots.has(i):
						result.placement_active_slots.append(i)
				TokenResource.EffectTarget.HP:
					card_hp += value
					if not result.placement_active_slots.has(i):
						result.placement_active_slots.append(i)
				TokenResource.EffectTarget.PRESSURE:
					if value != 0.0:
						result.pressure_bonus += value
						result.pressure_events.append({"slots": [i], "bonus": value})
						if not result.placement_active_slots.has(i):
							result.placement_active_slots.append(i)

		# Emit heal event for this card if HP was contributed
		if card_hp > 0.0:
			result.heal_events.append({"slot_index": i, "value": card_hp})

		# Auto ATK/DEF count for tokens with no explicit placement or streak effect
		if token.placement_slot == TokenResource.SlotPosition.NONE and \
				token.streak_target == TokenResource.EffectTarget.NONE:
			match token.token_type:
				TokenResource.TokenType.ATTACK: result.atk_count += 1
				TokenResource.TokenType.DEFENSE: result.def_count += 1

	_resolve_streaks(cards, result)

	result.total_attack = roundi(GameManager.base_damage * result.atk_count)
	result.total_defense = roundi(GameManager.base_defense * result.def_count)
	return result


static func _placement_met(slot: TokenResource.SlotPosition, card_index: int, slot_index: int, total_slots: int) -> bool:
	match slot:
		TokenResource.SlotPosition.FIRST: return slot_index == 0
		TokenResource.SlotPosition.LAST:  return slot_index == total_slots - 1
		_: return false


static func _resolve_streaks(cards: Array, result: ResolveResult) -> void:
	var i := 0
	while i < cards.size():
		var token: TokenResource = cards[i].token_data
		if token.streak_target == TokenResource.EffectTarget.NONE:
			i += 1
			continue

		match token.streak_scope:
			TokenResource.StreakScope.CONSECUTIVE:
				var run_end := i
				while run_end + 1 < cards.size():
					var next: TokenResource = cards[run_end + 1].token_data
					if next.token_type == token.token_type and next.streak_target != TokenResource.EffectTarget.NONE:
						run_end += 1
					else:
						break
				_apply_consecutive(cards, i, run_end, result)
				i = run_end + 1

			TokenResource.StreakScope.ADJACENT:
				_apply_adjacent(cards, i, result)
				i += 1


static func _apply_consecutive(cards: Array, start: int, run_end: int, result: ResolveResult) -> void:
	var token: TokenResource = cards[start].token_data
	var run_len := run_end - start + 1

	match token.token_type:
		TokenResource.TokenType.ATTACK:  result.atk_count += run_len
		TokenResource.TokenType.DEFENSE: result.def_count += run_len

	if run_len < 2 or run_len < token.streak_min:
		return

	var bonus := token.streak_value_per_token * run_len
	var slot_indices := []
	for j in range(start, run_end + 1):
		slot_indices.append(j)
		if not result.streak_active_slots.has(j):
			result.streak_active_slots.append(j)

	match token.streak_target:
		TokenResource.EffectTarget.PRESSURE:
			result.pressure_bonus += bonus
			result.pressure_events.append({"slots": slot_indices, "bonus": bonus})


static func _apply_adjacent(cards: Array, card_index: int, result: ResolveResult) -> void:
	var token: TokenResource = cards[card_index].token_data
	var my_slot: int = cards[card_index].get_parent().slot_index
	var neighbors := 0
	for j in cards.size():
		if j == card_index:
			continue
		if cards[j].token_data.token_type != token.token_type:
			continue
		if abs(cards[j].get_parent().slot_index - my_slot) == 1:
			neighbors += 1

	if neighbors == 0 or neighbors < token.streak_min:
		return

	var bonus := token.streak_value_per_token * neighbors

	if not result.streak_active_slots.has(card_index):
		result.streak_active_slots.append(card_index)

	match token.streak_target:
		TokenResource.EffectTarget.HP:
			var merged := false
			for ev in result.heal_events:
				if ev["slot_index"] == card_index:
					ev["value"] += bonus
					merged = true
					break
			if not merged:
				result.heal_events.append({"slot_index": card_index, "value": bonus})
