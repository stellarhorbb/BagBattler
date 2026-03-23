class_name MoonPhaseResource
extends Resource

enum PhaseType { NEW_MOON, FIRST_QUARTER, FULL_MOON, LAST_QUARTER, BLOOD_MOON }

@export var phase_type: PhaseType = PhaseType.NEW_MOON
@export var phase_name: String = ""
@export var description: String = ""
@export var cost: int = 15

@export var atk_bonus: int = 0
@export var prsr_bonus: float = 0.0
@export var def_bonus: int = 0
@export var hp_bonus: int = 0
@export var hp_bonus_percent: float = 0.0
