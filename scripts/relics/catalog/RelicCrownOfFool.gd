class_name RelicCrownOfFool
extends BaseRelic

func _init():
	relic_data = preload("res://resources/relics/crown_of_fool.tres")

func on_execute(context: Dictionary) -> Dictionary:
	if context.get("hazard_count") == 1:
		context["gold"] = context.get("gold", 0) + 1
		print("[CrownOfFool] Hazard count is 1 — granted 1 gold.")
	return context
