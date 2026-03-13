class_name EffectRampart
extends BaseEffect

func apply(context: CombatContext) -> void:
	if context.is_last:
		context.result.rampart_active = true
		print("🛡️ RAMPART actif en dernier !")
