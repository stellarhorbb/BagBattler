class_name TokenResource
extends Resource

enum TokenType    { ATTACK, DEFENSE, MODIFIER, UTILITY, CLEANSER, HAZARD }
enum SlotPosition { NONE, FIRST, LAST }
enum EffectTarget { NONE, PRESSURE, HP, DAMAGE_MULT }
enum StreakScope   { CONSECUTIVE, ADJACENT }
# CONSECUTIVE = run of same-type tokens (Strike, Guard)
# ADJACENT    = direct neighbors of any type (Heal)

@export var token_name: String = "Token"
@export var token_type: TokenType = TokenType.ATTACK
@export var description: String = ""
@export var value: int = 1
@export var weight: float = 1.0
@export var shop_drop_weight: float = 1.0
@export var shop_price: int = 0

# Placement — fires only when token is at the right slot
@export_group("Placement")
@export var placement_slot: SlotPosition = SlotPosition.NONE
@export var placement_target: EffectTarget = EffectTarget.NONE
@export var placement_value: float = 0.0
@export var placement_count_scale: bool = false   # if true: value × count of placement_count_type on line
@export var placement_count_type: TokenType = TokenType.DEFENSE
@export var placement_bonus_description: String = ""

# Streak — bonus per token count
@export_group("Streak")
@export var streak_target: EffectTarget = EffectTarget.NONE
@export var streak_scope: StreakScope = StreakScope.CONSECUTIVE
@export var streak_min: int = 2
@export var streak_value_per_token: float = 0.0
@export var streak_bonus_description: String = ""

# Base — always fires on execute
@export_group("Base")
@export var base_target: EffectTarget = EffectTarget.NONE
@export var base_value: float = 0.0
