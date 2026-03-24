class_name ResolveResult
extends Resource

var total_attack: int = 0
var total_defense: int = 0
var damage_multiplier: float = 1.0
var placement_active_slots: Array[int] = []  # placement effect met → wave ring on slot
var streak_active_slots: Array[int] = []     # streak bonus triggered → colored outline on card
var inactive_slots: Array[int] = []          # placement token not at required slot
var atk_count: int = 0
var def_count: int = 0
var pressure_bonus: float = 0.0
var pressure_events: Array = []    # [{slots: Array[int], bonus: float}]
var heal_events: Array = []        # [{slot_index: int, value: float}]
var damage_mult_events: Array = [] # [{slot_index: int, value: float}]
var streak_count: int = 0        # number of distinct streak groups that fired
