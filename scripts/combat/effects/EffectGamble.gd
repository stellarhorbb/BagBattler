class_name EffectGamble
extends BaseEffect

func apply(context: CombatContext) -> void:
	var gained := randi_range(0, 6)
	context.result.bonus_gold += gained
	print("🎲 GAMBLE : +%d gold" % gained)
