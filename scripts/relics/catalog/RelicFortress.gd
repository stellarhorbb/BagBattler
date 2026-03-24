class_name RelicFortress
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/fortress.tres")

# Each empty slot adds +2 DEF when it is passed during slot resolution.
func on_empty_slot(context: Dictionary) -> Dictionary:
	context["total_defense"] = context.get("total_defense", 0) + 2
	return context
