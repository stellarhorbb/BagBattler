class_name RelicUnderPressure
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/under_pressure.tres")

func on_reward_screen() -> void:
	if not GameManager.is_boss_zone():
		GameManager.pending_pressure_boost += GameManager.last_combat_pressure * 0.1
