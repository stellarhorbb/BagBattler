class_name RelicAngel
extends BaseRelic

func _init():
	relic_data = preload("res://resources/relics/angel.tres")

func on_before_crash(draw_count: int, hazard_count: int) -> bool:
	# Protect only when the very first 2 draws are both hazards
	return draw_count == 2 and hazard_count == 2
