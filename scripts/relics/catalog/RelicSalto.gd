class_name RelicSalto
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/salto.tres")

# +0.05 pressure per 10 salt in wallet.
func on_execute(context: Dictionary) -> Dictionary:
	var salt: int = context.get("gold", 0)
	var bonus: float = floorf(salt / 10.0) * 0.05
	if bonus > 0.0:
		context["pressure"] = context.get("pressure", 1.0) + bonus
	return context
