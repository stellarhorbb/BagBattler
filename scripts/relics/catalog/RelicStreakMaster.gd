class_name RelicStreakMaster
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/streak_master.tres")

func get_streak_multiplier() -> float:
	return 2.0
