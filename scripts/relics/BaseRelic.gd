class_name BaseRelic
extends Resource

@export var relic_data: RelicResource

func on_execute(context: Dictionary) -> Dictionary:
	return context

func on_hazard_drawn() -> void:
	pass

func on_before_crash() -> bool:
	return false

func on_reward_screen() -> void:
	pass

func reset_combat_state() -> void:
	pass
