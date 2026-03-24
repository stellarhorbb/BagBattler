class_name RelicCollector
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/collector.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var has_atk: bool = context.get("atk_count", 0) > 0
	var has_def: bool = context.get("def_count", 0) > 0
	var has_other: bool = context.get("has_other_type", false)
	if has_atk and has_def and has_other:
		context["pressure"] = context.get("pressure", 1.0) + 0.1
	return context
