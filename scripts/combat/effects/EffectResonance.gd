class_name EffectResonance
extends BaseEffect

func apply(context: CombatContext) -> void:
	var types := {}
	for card in context.cards:
		types[card.token_data.token_type] = true
	if types.size() >= 4:
		context.result.resonance_triggered = true
		print("🌊 RESONANCE : %d types → +1 ATK de base permanent" % types.size())
	else:
		print("🌊 RESONANCE : seulement %d type(s) sur la ligne, pas de bonus" % types.size())
