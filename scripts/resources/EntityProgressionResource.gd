class_name EntityProgressionResource
extends Resource

@export var zones: Array[ZoneStatsResource] = []

func get_stats(zone_number: int) -> ZoneStatsResource:
	for z in zones:
		if z.zone_number == zone_number:
			return z
	return null
