class_name RelicIronTide
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/iron_tide.tres")

func on_defense_negate() -> int:
	return 2
