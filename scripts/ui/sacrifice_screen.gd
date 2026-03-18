extends Control

@onready var token_row: HBoxContainer = $ContentVBox/TokenRow
@onready var button_confirm: Button = $ContentVBox/ButtonConfirm

const TOKEN_CARD = preload("res://token_card.tscn")
const FONT_BLACK = preload("res://font/LondrinaSolid-Black.ttf")
const MAX_CHOICES := 7
const BG_COLOR := Color(0.91, 0.16, 0.29, 1)

var _candidates: Array[TokenResource] = []
var _selected_index: int = -1
var _select_buttons: Array[Button] = []

func _ready() -> void:
	button_confirm.disabled = true
	button_confirm.pressed.connect(_on_confirm_pressed)
	_build_candidates()
	_build_cards()

func _build_candidates() -> void:
	var pool: Array[TokenResource] = []
	for token in GameManager.full_bag:
		if token.token_type != TokenResource.TokenType.HAZARD:
			pool.append(token)
	pool.shuffle()
	_candidates = pool.slice(0, min(MAX_CHOICES, pool.size()))

func _build_cards() -> void:
	for i in _candidates.size():
		var token := _candidates[i]

		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 14)
		card.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon: Control = TOKEN_CARD.instantiate()
		card.add_child(icon)
		token_row.add_child(card)
		icon.setup(token)

		var label := Label.new()
		label.text = token.token_name.to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", FONT_BLACK)
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Color.WHITE)
		card.add_child(label)

		var btn := Button.new()
		btn.text = "SELECT"
		btn.custom_minimum_size = Vector2(130, 44)
		btn.add_theme_font_override("font", FONT_BLACK)
		btn.add_theme_font_size_override("font_size", 22)
		var idx := i
		btn.pressed.connect(func(): _on_select(idx))
		card.add_child(btn)

		_select_buttons.append(btn)

	_refresh_buttons()

func _on_select(index: int) -> void:
	_selected_index = index if _selected_index != index else -1
	_refresh_buttons()
	button_confirm.disabled = _selected_index == -1

func _refresh_buttons() -> void:
	for i in _select_buttons.size():
		var btn := _select_buttons[i]
		if i == _selected_index:
			btn.text = "SELECTED"
			_apply_btn_style(btn, true)
		else:
			btn.text = "SELECT"
			_apply_btn_style(btn, false)

func _apply_btn_style(btn: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	if selected:
		style.bg_color = BG_COLOR
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	else:
		style.bg_color = Color.WHITE
		btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
		btn.add_theme_color_override("font_hover_color", Color(0.08, 0.08, 0.08, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.08, 0.08, 1))
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _on_confirm_pressed() -> void:
	if _selected_index == -1:
		return
	var token := _candidates[_selected_index]
	GameManager.full_bag.erase(token)
	GameManager.purchased_tokens.erase(token)
	GameManager.sacrificed_tokens.append(token)
	GameManager.advance_round()
	get_tree().change_scene_to_file("res://shop_screen.tscn")
