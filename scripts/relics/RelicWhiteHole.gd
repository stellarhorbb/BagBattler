class_name RelicWhiteHole
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/white_hole.tres")

# Each empty slot on Execute adds +0.2 to pressure.
func on_execute(context: Dictionary) -> Dictionary:
	var empty: int = context.get("empty_slot_count", 0)
	if empty > 0:
		context["pressure"] = context.get("pressure", 1.0) + empty * 0.2
		var steps: Array = []
		for _i in empty:
			steps.append(0.2)
		context["pressure_steps"] = steps
	return context
