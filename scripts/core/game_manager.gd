extends Node

var selected_job: JobResource = null
var current_round: int = 1
var gold: int = 0
var turns_played_last_combat: int = 0
var base_damage: int
var base_defense: int
var pressure_increment: float = 0.1
var player_max_hp: int
var player_current_hp: int = 80
var purchased_tokens: Array[TokenResource] = []
var purchased_relics: Array[BaseRelic] = []
var sacrificed_tokens: Array[TokenResource] = []
var full_bag: Array[TokenResource] = []

# Charge la progression de l'entité
var entity_progression: EntityProgressionResource = preload("res://resources/entity/entity_progression.tres")

func reset_run() -> void:
	selected_job = null
	current_round = 1
	gold = 0
	turns_played_last_combat = 0
	purchased_tokens.clear()
	purchased_relics.clear()
	sacrificed_tokens.clear()
	full_bag.clear()
	RelicManager.relics.clear()
	player_current_hp = player_max_hp

func init_run_stats(job: JobResource) -> void:
	base_damage = job.base_damage
	base_defense = job.base_defense
	pressure_increment = 0.1
	player_max_hp = job.base_hp
	player_current_hp = player_max_hp

func calculate_combat_reward() -> int:
	var reward = 5
	if turns_played_last_combat < 5:
		reward += 2
	elif turns_played_last_combat > 10:
		reward -= 3
	return max(reward, 0)

# Retourne les stats du round actuel
func get_current_stats() -> RoundStatsResource:
	return entity_progression.get_stats(current_round)

# Ante affiché au joueur (calculé automatiquement)
func get_current_ante() -> int:
	return ceil(current_round / 4.0)

# Round dans l'ante (1, 2, 3 ou 4)
func get_round_in_ante() -> int:
	return ((current_round - 1) % 4) + 1

# C'est un boss si c'est le 4ème round de l'ante
func is_boss_round() -> bool:
	return get_round_in_ante() == 4

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

func advance_round() -> void:
	current_round += 1
	if get_round_in_ante() == 1:
		heal_end_of_ante()
