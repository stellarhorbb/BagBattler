class_name EffectReckless
extends BaseEffect

func apply(context: CombatContext) -> void:
	context.result.reckless_triggered = true
	print("🔥 RECKLESS : +0.5 ATK de base permanent")
