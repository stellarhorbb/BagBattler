class_name EntityProgressionResource
extends Resource

@export var rounds: Array[RoundStatsResource] = []

func get_stats(round_number: int) -> RoundStatsResource:
	for r in rounds:
		if r.round_number == round_number:
			return r
	return null
