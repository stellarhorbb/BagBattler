class_name BaseRelic
extends Resource

@export var relic_data: RelicResource

func on_execute(context: Dictionary) -> Dictionary:
	return context

func on_hazard_drawn() -> int:
	return 0

func on_before_crash(draw_count: int, hazard_count: int) -> bool:
	return false

func on_pressure_mult(context: Dictionary) -> Dictionary:
	return context

func on_deathblow(context: Dictionary) -> Dictionary:
	return context

func on_reward_screen() -> void:
	pass

func reset_combat_state() -> void:
	pass
