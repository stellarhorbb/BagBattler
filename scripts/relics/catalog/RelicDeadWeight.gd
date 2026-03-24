class_name RelicDeadWeight
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/dead_weight.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var sacrificed: int = GameManager.sacrificed_tokens.size()
	if sacrificed > 0:
		context["total_attack"] = context.get("total_attack", 0) + sacrificed
	return context
