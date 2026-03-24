class_name RelicTidalMass
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/tidal_mass.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var phases: int = GameManager.purchased_moon_phases.size()
	if phases > 0:
		var bonus: int = roundi(phases * 0.5)
		if bonus > 0:
			context["total_attack"] = context.get("total_attack", 0) + bonus
			context["total_defense"] = context.get("total_defense", 0) + bonus
	return context
