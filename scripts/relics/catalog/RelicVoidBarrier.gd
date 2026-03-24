class_name RelicVoidBarrier
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/void_barrier.tres")

func on_execute(context: Dictionary) -> Dictionary:
	var atks: int = context.get("atk_count", 0)
	if atks == 0:
		context["total_defense"] = context.get("total_defense", 0) + 5
	return context
