extends Node

var selected_job: JobResource = null
var current_zone: int = 1
var gold: int = 0
var total_salt_earned: int = 0
var total_crashes: int = 0
var shells_opened: int = 0
var purchased_echoes: Array = []
var base_pressure_floor: float = 1.0   # permanent run stat, raised by Moon Phase upgrades
var pending_pressure_boost: float = 0.0 # temporary next-zone bonus from rewards
var slot_count: int = 6
var turns_played_last_combat: int = 0
var base_damage: int
var base_defense: int
var base_damage_fractional: float = 0.0
var pressure_increment: float = 0.1
var player_max_hp: int
var player_current_hp: int = 80
var purchased_tokens: Array[TokenResource] = []
var purchased_relics: Array[BaseRelic] = []
var purchased_moon_phases: Array[MoonPhaseResource] = []
var sacrificed_tokens: Array[TokenResource] = []
var full_bag: Array[TokenResource] = []
var streak_bonus_multiplier: float = 1.0
var streak_extra_count: int = 0
var last_combat_pressure: float = 1.0

# Charge la progression de l'entité
var entity_progression: EntityProgressionResource = preload("res://resources/entity/entity_progression.tres")

func reset_run() -> void:
	selected_job = null
	current_zone = 1
	gold = 0
	total_salt_earned = 0
	total_crashes = 0
	shells_opened = 0
	purchased_echoes.clear()
	base_pressure_floor = 1.0
	pending_pressure_boost = 0.0
	slot_count = 6
	turns_played_last_combat = 0
	base_damage_fractional = 0.0
	purchased_tokens.clear()
	purchased_relics.clear()
	purchased_moon_phases.clear()
	sacrificed_tokens.clear()
	full_bag.clear()
	streak_bonus_multiplier = 1.0
	streak_extra_count = 0
	RelicManager.relics.clear()
	player_current_hp = player_max_hp

func init_run_stats(job: JobResource) -> void:
	base_damage = job.base_damage
	base_defense = job.base_defense
	base_damage_fractional = 0.0
	pressure_increment = 0.1
	player_max_hp = job.base_hp
	player_current_hp = player_max_hp
	slot_count = job.slot_count

func calculate_combat_reward() -> int:
	var reward = 10
	if turns_played_last_combat <= 1:
		reward += 5
	elif turns_played_last_combat <= 2:
		reward += 2
	elif turns_played_last_combat >= 10:
		reward -= 5
	elif turns_played_last_combat >= 7:
		reward -= 2
	return max(reward, 0)

# Retourne les stats de la zone actuelle
func get_current_stats() -> ZoneStatsResource:
	return entity_progression.get_stats(current_zone)

# Ante affiché au joueur (calculé automatiquement)
func get_current_ante() -> int:
	return ceil(current_zone / 4.0)

# Zone dans l'ante (1, 2, 3 ou 4)
func get_zone_in_ante() -> int:
	return ((current_zone - 1) % 4) + 1

# C'est un boss si c'est la 4ème zone de l'ante
func is_boss_zone() -> bool:
	return get_zone_in_ante() == 4

const DEPTH_NAMES := [
	"The Surface",
	"Sunlight Depths",
	"Twilight Depths",
	"Midnight Depths",
	"Abyssal Depths",
	"Hadal Depths",
]

func get_depth_name() -> String:
	var ante = get_current_ante()
	if ante <= DEPTH_NAMES.size():
		return DEPTH_NAMES[ante - 1]
	return "The Abyss"

func heal_end_of_ante() -> void:
	player_current_hp = min(player_current_hp + roundi(player_max_hp * 0.25), player_max_hp)

func get_effective_bag() -> Array[TokenResource]:
	return full_bag

func advance_zone() -> void:
	current_zone += 1
	if get_zone_in_ante() == 1:
		heal_end_of_ante()

func add_gold(amount: int) -> void:
	gold += amount
	if amount > 0:
		total_salt_earned += amount

func apply_moon_phase(phase: MoonPhaseResource) -> void:
	purchased_moon_phases.append(phase)
	base_damage += phase.atk_bonus
	base_pressure_floor += phase.prsr_bonus
	base_defense += phase.def_bonus
	var flat_hp := phase.hp_bonus + roundi(player_max_hp * phase.hp_bonus_percent / 100.0)
	player_max_hp += flat_hp
	player_current_hp = min(player_current_hp + flat_hp, player_max_hp)
