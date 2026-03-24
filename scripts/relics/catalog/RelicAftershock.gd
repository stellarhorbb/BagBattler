class_name RelicAftershock
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/aftershock.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var streaks: int = context.get("streak_count", 0)
	if streaks > 0:
		context["total_attack"] = context.get("total_attack", 0) + streaks * 2
	return context
