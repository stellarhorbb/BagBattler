class_name RelicDepthCount
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/depth_count.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var hzd: int = context.get("bag_hazard_count", 0)
	if hzd > 0:
		var current_pressure: float = context.get("pressure", 1.0)
		context["pressure"] = current_pressure * pow(1.2, hzd)
	return context
