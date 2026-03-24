class_name RelicPredator
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/predator.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var defs: int = context.get("def_count", 0)
	if defs > 0:
		context["total_attack"] = context.get("total_attack", 0) + defs * 3
	return context
