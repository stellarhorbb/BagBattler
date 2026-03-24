class_name RelicWhiteHole
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/white_hole.tres")

# Each empty slot adds +0.2 PRSR when it is passed during slot resolution.
func on_empty_slot(context: Dictionary) -> Dictionary:
	context["pressure"] = context.get("pressure", 1.0) + 0.2
	return context
