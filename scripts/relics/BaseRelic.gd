class_name BaseRelic
extends Resource

@export var relic_data: RelicResource

func on_execute(context: Dictionary) -> Dictionary:
	return context

func on_empty_slot(context: Dictionary) -> Dictionary:
	return context

func on_hazard_drawn() -> int:
	return 0

func on_before_crash(_draw_count: int, _hazard_count: int) -> bool:
	return false

func on_pressure_mult(context: Dictionary) -> Dictionary:
	return context

func on_deathblow(context: Dictionary) -> Dictionary:
	return context

func on_crash(context: Dictionary) -> Dictionary:
	return context

func on_defense_negate() -> int:
	return 0

func get_streak_multiplier() -> float:
	return 1.0

func get_streak_extra() -> int:
	return 0

func on_reward_screen() -> void:
	pass

func reset_combat_state() -> void:
	pass
