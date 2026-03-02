extends Control

@onready var compact_view = $CompactView
@onready var modal_view = $ModalView
@onready var modal_content = $ModalView/ScrollContainer/ModalContent
@onready var circles_container = $CompactView/CirclesContainer

var bag_manager: BagManager

# Couleurs par type de jeton
const TYPE_COLORS = {
	TokenResource.TokenType.ATTACK: Color("ce002d"),
	TokenResource.TokenType.DEFENSE: Color("004397"),
	TokenResource.TokenType.MODIFIER: Color("6a0dad"),
	TokenResource.TokenType.UTILITY: Color("ffd700"),
	TokenResource.TokenType.CLEANSER: Color("e0e0e0"),
	TokenResource.TokenType.HAZARD: Color("2a2a2a"),
}

func setup(bm: BagManager) -> void:
	bag_manager = bm
	refresh()

func refresh() -> void:
	_build_compact_view()
	if modal_view.visible:
		_build_modal_view()

# --- VUE COMPACTE ---
# Ordre fixe des types — toujours affiché même à 0
const TYPE_ORDER = [
	TokenResource.TokenType.ATTACK,
	TokenResource.TokenType.DEFENSE,
	TokenResource.TokenType.MODIFIER,
	TokenResource.TokenType.UTILITY,
	TokenResource.TokenType.CLEANSER,
	TokenResource.TokenType.HAZARD,
]

func _build_compact_view() -> void:
	for child in circles_container.get_children():
		child.free()
	
	var composition = bag_manager.get_bag_composition()
	
	# Utilise des int pour éviter les problèmes de comparaison d'enum
	var initial_types: Array[int] = []
	for token in bag_manager.initial_bag:
		var t = int(token.token_type)
		if not initial_types.has(t):
			initial_types.append(t)
	
	for token_type in TYPE_ORDER:
		if not initial_types.has(int(token_type)):
			continue
		
		var total_count = 0
		if composition.has(token_type):
			for token_name in composition[token_type]:
				total_count += composition[token_type][token_name]["count"]
		
		var circle = _make_circle(token_type, total_count)
		circles_container.add_child(circle)
	
	var label = Label.new()
	label.text = "%d" % bag_manager.bag.size()
	label.add_theme_font_size_override("font_size", 24)
	circles_container.add_child(label)

# --- MODAL ---
func _build_modal_view() -> void:
	for child in modal_content.get_children():
		child.free()
	
	var composition = bag_manager.get_bag_composition()
	
	var initial_types: Array[int] = []
	for token in bag_manager.initial_bag:
		var t = int(token.token_type)
		if not initial_types.has(t):
			initial_types.append(t)
	
	for token_type in TYPE_ORDER:
		if not initial_types.has(int(token_type)):
			continue
		
		# Header de section
		var header = Label.new()
		header.text = TokenResource.TokenType.keys()[token_type].to_upper()
		header.add_theme_font_size_override("font_size", 20)
		modal_content.add_child(header)
		
		modal_content.add_child(HSeparator.new())
		
		# Lignes — seulement si le type existe encore dans le sac
		if composition.has(token_type):
			var type_data = composition[token_type]
			for token_name in type_data:
				var data = type_data[token_name]
				var row = _make_row(token_type, token_name, data["count"], data["percent"])
				modal_content.add_child(row)
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		modal_content.add_child(spacer)

# --- TOGGLE MODAL ---
func _ready() -> void:
	compact_view.pressed.connect(_on_compact_pressed)

func _on_compact_pressed() -> void:
	modal_view.visible = !modal_view.visible
	if modal_view.visible:
		_build_modal_view()

# --- HELPERS ---
func _make_circle(token_type: int, count: int) -> Control:
	var circle = Panel.new()
	circle.custom_minimum_size = Vector2(60, 60)
	
	var style = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(token_type, Color.WHITE)
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	circle.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "×%d" % count
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	circle.add_child(label)
	
	return circle

func _make_row(token_type: int, token_name: String, count: int, percent: float) -> HBoxContainer:
	var row = HBoxContainer.new()
	
	# Cercle coloré
	var dot = Panel.new()
	dot.custom_minimum_size = Vector2(20, 20)
	var style = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(token_type, Color.WHITE)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	dot.add_theme_stylebox_override("panel", style)
	row.add_child(dot)
	
	# Nom + count
	var name_label = Label.new()
	name_label.text = "  %s  ×%d" % [token_name, count]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	row.add_child(name_label)
	
	# Pourcentage
	var pct_label = Label.new()
	pct_label.text = "%d%%" % roundi(percent)
	pct_label.add_theme_font_size_override("font_size", 18)
	row.add_child(pct_label)
	
	return row
