extends PanelContainer

@onready var label_name: Label = $VBox/BodyMargin/BodyContent/LabelName
@onready var label_type: Label = $VBox/BodyMargin/BodyContent/LabelType
@onready var label_description: Label = $VBox/BodyMargin/BodyContent/LabelDescription
@onready var effect_block: VBoxContainer = $VBox/BodyMargin/BodyContent/EffectBlock
@onready var slot_dots_row: HBoxContainer = $VBox/BodyMargin/BodyContent/EffectBlock/SlotDotsRow
@onready var label_effect: Label = $VBox/BodyMargin/BodyContent/EffectBlock/LabelEffect

const TYPE_NAMES := {
	TokenResource.TokenType.ATTACK:   "ATTACK",
	TokenResource.TokenType.DEFENSE:  "DEFENSE",
	TokenResource.TokenType.MODIFIER: "MODIFIER",
	TokenResource.TokenType.UTILITY:  "UTILITY",
	TokenResource.TokenType.CLEANSER: "CLEANSER",
	TokenResource.TokenType.HAZARD:   "HAZARD",
}

const TYPE_COLORS := {
	TokenResource.TokenType.ATTACK:   Color("#E8294A"),
	TokenResource.TokenType.DEFENSE:  Color("#3D4CE8"),
	TokenResource.TokenType.MODIFIER: Color("#7B2FE8"),
	TokenResource.TokenType.UTILITY:  Color("#44AA66"),
	TokenResource.TokenType.CLEANSER: Color("#44AACC"),
	TokenResource.TokenType.HAZARD:   Color("#888888"),
}

const N_SLOTS := 5

func setup(data: TokenResource) -> void:
	label_name.text = data.token_name.to_upper()

	var type_color: Color = TYPE_COLORS.get(data.token_type, Color.WHITE)
	label_type.text = TYPE_NAMES.get(data.token_type, "UNKNOWN")
	label_type.add_theme_color_override("font_color", type_color)

	label_description.text = data.description if data.description != "" else "No description."

	if data.effect != TokenResource.TokenEffect.NONE:
		effect_block.visible = true
		_build_slot_dots(data.effect, type_color)
		_set_effect_label(data.effect)
	else:
		effect_block.visible = false

func _build_slot_dots(effect: TokenResource.TokenEffect, color: Color) -> void:
	for child in slot_dots_row.get_children():
		slot_dots_row.remove_child(child)
		child.free()

	# active_indices: which slots are highlighted. Connectors only drawn between two adjacent active slots.
	var active_indices: Array[int] = []
	match effect:
		TokenResource.TokenEffect.PROVOCATION: active_indices = [0]
		TokenResource.TokenEffect.RAMPART:     active_indices = [N_SLOTS - 1]

	for i in N_SLOTS:
		if i > 0:
			var connector := ColorRect.new()
			connector.custom_minimum_size = Vector2(14, 4)
			connector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var both_active := active_indices.has(i - 1) and active_indices.has(i)
			connector.color = color if both_active else Color("#444444")
			slot_dots_row.add_child(connector)

		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(22, 22)
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 11
		style.corner_radius_top_right = 11
		style.corner_radius_bottom_right = 11
		style.corner_radius_bottom_left = 11
		style.bg_color = color if active_indices.has(i) else Color("#444444")
		dot.add_theme_stylebox_override("panel", style)
		slot_dots_row.add_child(dot)

func _set_effect_label(effect: TokenResource.TokenEffect) -> void:
	match effect:
		TokenResource.TokenEffect.PROVOCATION:
			label_effect.text = "Reduces Entity DMG by 75% if placed on the first slot."
		TokenResource.TokenEffect.RAMPART:
			label_effect.text = "Only activates if placed on the last slot with at least one DEF token before it."
		_:
			label_effect.text = ""
