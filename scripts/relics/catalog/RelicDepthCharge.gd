class_name RelicDepthCharge
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/depth_charge.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var hzd: int = context.get("bag_hazard_count", 0)
	if hzd > 0:
		context["total_attack"] = context.get("total_attack", 0) + hzd * 2
	return context
