extends PanelContainer

@onready var label_name: Label = $VBox/BodyMargin/BodyContent/LabelName
@onready var label_type: Label = $VBox/BodyMargin/BodyContent/LabelType
@onready var label_description: Label = $VBox/BodyMargin/BodyContent/LabelDescription
@onready var effect_block: VBoxContainer = $VBox/BodyMargin/BodyContent/EffectBlock
@onready var label_effect_title: Label = $VBox/BodyMargin/BodyContent/EffectBlock/LabelEffectTitle
@onready var slot_dots_row: HBoxContainer = $VBox/BodyMargin/BodyContent/EffectBlock/SlotDotsRow
@onready var label_effect: Label = $VBox/BodyMargin/BodyContent/EffectBlock/LabelEffect
@onready var combo_block: VBoxContainer = $VBox/BodyMargin/BodyContent/ComboBlock
@onready var combo_rules_container: VBoxContainer = $VBox/BodyMargin/BodyContent/ComboBlock/ComboRulesContainer

const FONT_BLACK = preload("res://font/LondrinaSolid-Black.ttf")

const TYPE_NAMES := {
	TokenResource.TokenType.ATTACK:   "ATTACK",
	TokenResource.TokenType.DEFENSE:  "DEFENSE",
	TokenResource.TokenType.MODIFIER: "MODIFIER",
	TokenResource.TokenType.UTILITY:  "UTILITY",
	TokenResource.TokenType.CLEANSER: "CLEANSER",
	TokenResource.TokenType.HAZARD:   "SKULL",
}

const TYPE_COLORS := {
	TokenResource.TokenType.ATTACK:   Color("#E8294A"),
	TokenResource.TokenType.DEFENSE:  Color("#3D4CE8"),
	TokenResource.TokenType.MODIFIER: Color("#7B2FE8"),
	TokenResource.TokenType.UTILITY:  Color("#EAA21C"),
	TokenResource.TokenType.CLEANSER: Color("#44AACC"),
	TokenResource.TokenType.HAZARD:   Color("#888888"),
}

func setup(data: TokenResource) -> void:
	label_name.text = data.token_name.to_upper()

	var type_color: Color = TYPE_COLORS.get(data.token_type, Color.WHITE)
	label_type.text = TYPE_NAMES.get(data.token_type, "UNKNOWN")
	label_type.add_theme_color_override("font_color", type_color)

	label_description.text = data.description if data.description != "" else "No description."

	var has_placement := data.placement_slot != TokenResource.SlotPosition.NONE
	var has_base := data.base_target != TokenResource.EffectTarget.NONE
	if has_placement or has_base:
		effect_block.visible = true
		label_effect_title.text = "PLACEMENT" if has_placement else "BASE"
		_build_slot_dots(data, type_color)
		label_effect.text = data.placement_bonus_description if data.placement_bonus_description != "" else _build_effect_label(data)
	else:
		effect_block.visible = false

	if data.streak_target != TokenResource.EffectTarget.NONE:
		combo_block.visible = true
		_build_streak_block(data, type_color)
	else:
		combo_block.visible = false


func _build_slot_dots(data: TokenResource, color: Color) -> void:
	for child in slot_dots_row.get_children():
		slot_dots_row.remove_child(child)
		child.free()

	var active_indices: Array[int] = []
	var n_slots := GameManager.slot_count
	match data.placement_slot:
		TokenResource.SlotPosition.FIRST: active_indices = [0]
		TokenResource.SlotPosition.LAST:  active_indices = [n_slots - 1]

	for i in n_slots:
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


func _build_effect_label(data: TokenResource) -> String:
	var parts: Array[String] = []

	# Base effect (always-on)
	if data.base_target != TokenResource.EffectTarget.NONE:
		match data.base_target:
			TokenResource.EffectTarget.DAMAGE_MULT:
				parts.append("Reduces incoming damage by %d%%." % roundi(abs(data.base_value) * 100))
			TokenResource.EffectTarget.HP:
				parts.append("Recovers %d%% max HP." % roundi(data.base_value * 100))

	# Placement effect
	if data.placement_slot != TokenResource.SlotPosition.NONE and data.placement_target != TokenResource.EffectTarget.NONE:
		var slot_name := "first" if data.placement_slot == TokenResource.SlotPosition.FIRST else "last"
		match data.placement_target:
			TokenResource.EffectTarget.DAMAGE_MULT:
				var base_contrib: float = data.base_value if data.base_target == data.placement_target else 0.0
				var total: float = absf(base_contrib + data.placement_value)
				parts.append("At %s slot: total -%d%% damage." % [slot_name, roundi(total * 100)])
			TokenResource.EffectTarget.HP:
				if data.base_target == TokenResource.EffectTarget.HP:
					var total: float = data.base_value + data.placement_value
					parts.append("At %s slot: %d%% instead." % [slot_name, roundi(total * 100)])
				else:
					parts.append("At %s slot: +%d%% HP." % [slot_name, roundi(data.placement_value * 100)])
			TokenResource.EffectTarget.PRESSURE:
				if data.placement_count_scale:
					var type_name: String = TYPE_NAMES.get(data.placement_count_type, "token")
					parts.append("At %s slot: +%.2f Pressure per %s token." % [slot_name, data.placement_value, type_name])
				else:
					parts.append("At %s slot: +%.2f Pressure." % [slot_name, data.placement_value])

	return "\n".join(parts)


func _build_streak_block(data: TokenResource, color: Color) -> void:
	for child in combo_rules_container.get_children():
		combo_rules_container.remove_child(child)
		child.free()

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)

	# Dot count to show: streak_min dots (connected)
	var dot_count := data.streak_min
	if data.streak_scope == TokenResource.StreakScope.ADJACENT:
		dot_count = 2  # show 2 neighbors

	for j in dot_count:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(22, 22)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 11
		style.corner_radius_top_right = 11
		style.corner_radius_bottom_right = 11
		style.corner_radius_bottom_left = 11
		style.bg_color = color
		dot.add_theme_stylebox_override("panel", style)
		row.add_child(dot)

	var lbl := Label.new()
	if data.streak_bonus_description != "":
		lbl.text = data.streak_bonus_description
	else:
		match data.streak_target:
			TokenResource.EffectTarget.PRESSURE:
				lbl.text = "+%.2f Pressure/token" % data.streak_value_per_token
			TokenResource.EffectTarget.HP:
				lbl.text = "+%d%% HP/neighbor" % roundi(data.streak_value_per_token * 100)
	lbl.add_theme_font_override("font", FONT_BLACK)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", color)
	row.add_child(lbl)

	combo_rules_container.add_child(row)
