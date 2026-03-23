extends Node

signal relic_triggered(index: int)

const MAX_RELICS := 5

var relics: Array[BaseRelic] = []

func add_relic(relic: BaseRelic) -> bool:
	if relics.size() >= MAX_RELICS:
		return false
	relics.append(relic)
	return true

func remove_relic(relic: BaseRelic) -> void:
	relics.erase(relic)

func reorder(from: int, to: int) -> void:
	if from < 0 or from >= relics.size() or to < 0 or to >= relics.size():
		return
	var temp := relics[from]
	relics[from] = relics[to]
	relics[to] = temp

func trigger_execute(context: Dictionary) -> Dictionary:
	for i in relics.size():
		context = trigger_execute_single(i, context)
	return context

func trigger_execute_single(index: int, context: Dictionary) -> Dictionary:
	if index < 0 or index >= relics.size():
		return context
	var gold_before: int = context.get("gold", 0)
	var pressure_before: float = context.get("pressure", 0.0)
	context = relics[index].on_execute(context)
	if context.get("gold", 0) != gold_before or context.get("pressure", 0.0) != pressure_before:
		relic_triggered.emit(index)
	return context

func trigger_hazard_drawn() -> int:
	var bonus_damage := 0
	for i in relics.size():
		var dmg := relics[i].on_hazard_drawn()
		if dmg > 0:
			bonus_damage += dmg
			relic_triggered.emit(i)
	return bonus_damage

func trigger_before_crash(draw_count: int, hazard_count: int) -> bool:
	for i in relics.size():
		if relics[i].on_before_crash(draw_count, hazard_count):
			relic_triggered.emit(i)
			return true
	return false

func trigger_pressure_mult(context: Dictionary) -> Dictionary:
	for i in relics.size():
		var atk_before: int = context.get("final_attack", 0)
		context = relics[i].on_pressure_mult(context)
		if context.get("final_attack", 0) != atk_before:
			relic_triggered.emit(i)
	return context

func trigger_deathblow(context: Dictionary) -> Dictionary:
	for i in relics.size():
		var dmg_before: int = context.get("death_blow_damage", 0)
		context = relics[i].on_deathblow(context)
		if context.get("death_blow_damage", 0) != dmg_before:
			relic_triggered.emit(i)
	return context

func trigger_reward_screen() -> void:
	for relic in relics:
		relic.on_reward_screen()

func reset_combat_states() -> void:
	for relic in relics:
		relic.reset_combat_state()
