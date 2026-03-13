class_name TokenEffectResolver
extends Node

# Mapping effet → classe
static func get_effect(token: TokenResource) -> BaseEffect:
	match token.effect:
		TokenResource.TokenEffect.PROVOCATION:
			return EffectProvocation.new()
		TokenResource.TokenEffect.RAMPART:
			return EffectRampart.new()
		_:
			return null

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
		
		# Effets spéciaux
		var effect = get_effect(token)
		if effect:
			effect.apply(context)
			continue
		
		# Résolution de base (sans effet spécial)
		match token.token_type:
			TokenResource.TokenType.ATTACK:
				result.total_attack += GameManager.base_damage
			TokenResource.TokenType.DEFENSE:
				result.total_defense += GameManager.base_defense
				
	# Passe finale — Rampart double toute la défense accumulée			
	if result.rampart_active:
		result.total_defense *= 2
		print("🛡️ RAMPART : défense totale doublée → %d" % result.total_defense)
	
	return result
