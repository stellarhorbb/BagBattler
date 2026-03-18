class_name TokenEffectResolver
extends Node

static func get_effect(token: TokenResource) -> BaseEffect:
	match token.effect:
		TokenResource.TokenEffect.PROVOCATION:
			return EffectProvocation.new()
		TokenResource.TokenEffect.RAMPART:
			return EffectRampart.new()
		_:
			return null

static func _has_combo(token: TokenResource) -> bool:
	return not token.combo_thresholds.is_empty()

static func _get_combo_multiplier(token: TokenResource, run_len: int) -> float:
	var best := 1.0
	for i in token.combo_thresholds.size():
		if run_len >= int(token.combo_thresholds[i]):
			best = float(token.combo_multipliers[i])
	return best

static func _resolve_combos(cards: Array, result: ResolveResult) -> void:
	var i := 0
	while i < cards.size():
		var token: TokenResource = cards[i].token_data
		if not _has_combo(token):
			i += 1
			continue

		# Extend run as long as next card is same type with combo rules
		var run_end := i
		while run_end + 1 < cards.size():
			var next: TokenResource = cards[run_end + 1].token_data
			if next.token_type == token.token_type and _has_combo(next):
				run_end += 1
			else:
				break

		var run_len := run_end - i + 1
		var multiplier := _get_combo_multiplier(token, run_len)

		match token.token_type:
			TokenResource.TokenType.ATTACK:
				result.total_attack += roundi(run_len * float(GameManager.base_damage) * multiplier)
			TokenResource.TokenType.DEFENSE:
				result.total_defense += roundi(run_len * float(GameManager.base_defense) * multiplier)

		if multiplier > 1.0:
			for j in range(i, run_end + 1):
				if not result.active_combo_slots.has(j):
					result.active_combo_slots.append(j)

		i = run_end + 1

static func resolve(cards: Array) -> ResolveResult:
	var result = ResolveResult.new()
	var last_index = cards.size() - 1

	for i in cards.size():
		var token = cards[i].token_data
		var context = CombatContext.new()
		context.cards = cards
		context.card_index = i
		context.is_first = (i == 0)
		context.is_last = (i == last_index)
		context.result = result

		# Special effects (Provocation, Rampart…)
		var effect = get_effect(token)
		if effect:
			effect.apply(context)
			continue

		# Combo tokens are resolved in the second pass
		if _has_combo(token):
			continue

		match token.token_type:
			TokenResource.TokenType.ATTACK:
				result.total_attack += GameManager.base_damage
			TokenResource.TokenType.DEFENSE:
				result.total_defense += GameManager.base_defense

	# Second pass — quantity combo runs
	_resolve_combos(cards, result)

	# Final pass — Rampart doubles all accumulated defense
	if result.rampart_active:
		result.total_defense *= 2
		print("🛡️ RAMPART : défense totale doublée → %d" % result.total_defense)

	return result
