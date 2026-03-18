class_name RelicJellyfish
extends BaseRelic

func _init():
	relic_data = preload("res://resources/relics/jellyfish.tres")

func on_hazard_drawn() -> int:
	return GameManager.base_damage
