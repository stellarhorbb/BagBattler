class_name RelicSalvage
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/salvage.tres")

func on_crash(context: Dictionary) -> Dictionary:
	context["gold"] = context.get("gold", 0) + 3
	return context
