extends PanelContainer

@onready var header: Panel = $VBox/Header
@onready var label_rarity: Label = $VBox/Header/HeaderRow/LabelRarity
@onready var label_nature: Label = $VBox/Header/HeaderRow/LabelNature
@onready var label_name: Label = $VBox/BodyMargin/BodyContent/LabelName
@onready var label_effect: Label = $VBox/BodyMargin/BodyContent/LabelEffect
@onready var label_lore: Label = $VBox/BodyMargin/BodyContent/LabelLore

const RARITY_COLORS := {
	0: Color("454545"),
	1: Color("4a5eaa"),
	2: Color("2244ee"),
	3: Color("cc22aa"),
	4: Color("cc7700"),
}
const RARITY_NAMES := ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]

func setup(data: RelicResource) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = RARITY_COLORS.get(data.rarity, RARITY_COLORS[0])
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	header.add_theme_stylebox_override("panel", style)

	label_rarity.text = RARITY_NAMES[clamp(data.rarity, 0, 4)]
	label_nature.text = data.nature
	label_name.text = data.relic_name.to_upper()
	label_effect.text = data.description
	label_lore.text = data.lore
	label_lore.visible = data.lore != ""
