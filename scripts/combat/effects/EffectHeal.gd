class_name EffectHeal
extends BaseEffect

func apply(context: CombatContext) -> void:
	if context.is_last:
		context.result.heal_percent += 0.2
		print("💚 HEAL (dernier slot) : +20% HP")
	else:
		context.result.heal_percent += 0.1
		print("💚 HEAL : +10% HP")
