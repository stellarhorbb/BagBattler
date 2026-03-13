class_name EffectProvocation
extends BaseEffect

func apply(context: CombatContext) -> void:
	if context.is_first:
		context.result.damage_multiplier = 0.25  # 1er tiré → -75%
		print("🟣 PROVOCATION (1er) : dégâts ennemis -75%")
	else:
		context.result.damage_multiplier = 0.75  # sinon → -25%
		print("🟣 PROVOCATION : dégâts ennemis -25%")
