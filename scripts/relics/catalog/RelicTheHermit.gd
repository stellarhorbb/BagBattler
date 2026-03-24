class_name RelicTheHermit
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/the_hermit.tres")

func on_crash(context: Dictionary) -> Dictionary:
	var defs: int = context.get("def_count", 0)
	if defs > 0:
		var reduction: float = minf(defs * 0.15, 0.9)
		var dmg: int = context.get("damage", 0)
		context["damage"] = roundi(dmg * (1.0 - reduction))
	return context
