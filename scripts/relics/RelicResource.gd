class_name RelicResource
extends Resource

enum RelicTrigger {
	DRAW,        ## Step 0 — hazard drawn or crash prevention
	RESOLUTION,  ## Step 2 — after token effects, relic activation
	PRESSURE,    ## Step 3 — after pressure multiplier, before ATK/DEF resolve
	DEATHBLOW,   ## Step 7 — entity killed, before death blow damage
}

@export var relic_name: String = ""
@export var nature: String = "RELIC"
@export var description: String = ""
@export var lore: String = ""
@export var rarity: int = 0
@export var cost: int = 0
@export var icon: Texture2D
@export var emoji: String = ""
@export var color: Color = Color.WHITE
@export var trigger_step: RelicTrigger = RelicTrigger.RESOLUTION
