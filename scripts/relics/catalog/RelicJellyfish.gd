class_name RelicTrident
extends BaseRelic

var _used: bool = false

func _init():
	relic_data = preload("res://resources/relics/jellyfish.tres")

func on_hazard_drawn() -> int:
	if _used:
		return 0
	_used = true
	return GameManager.base_damage

func reset_combat_state() -> void:
	_used = false
