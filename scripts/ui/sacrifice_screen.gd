extends Control

@onready var token_row: HBoxContainer = $TokenRow
@onready var button_confirm: Button = $ButtonConfirm

const TOKEN_CARD = preload("res://token_card.tscn")
const FONT_BLACK = preload("res://font/LondrinaSolid-Black.ttf")
const MAX_CHOICES := 4

var _candidates: Array[TokenResource] = []
var _selected_index: int = -1
var _token_cards: Array = []

func _ready() -> void:
	button_confirm.disabled = true
	button_confirm.focus_mode = Control.FOCUS_NONE
	button_confirm.pressed.connect(_on_confirm_pressed)
	_build_candidates()
	_build_cards()
	RunHUD.visible = true
	RunHUD.set_info_color(Color.WHITE)
	RunHUD.refresh()

func _build_candidates() -> void:
	var pool: Array[TokenResource] = []
	for token in GameManager.full_bag:
		if token.token_type != TokenResource.TokenType.HAZARD:
			pool.append(token)
	pool.shuffle()
	_candidates = pool.slice(0, min(MAX_CHOICES, pool.size()))

func _build_cards() -> void:
	_token_cards.clear()
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
		label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
		card.add_child(label)

		_token_cards.append(icon)
		var idx := i
		icon.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton \
					and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed:
				_on_select(idx)
		)

func _on_select(index: int) -> void:
	_selected_index = index if _selected_index != index else -1
	for i in _token_cards.size():
		_token_cards[i].set_selected(i == _selected_index)
	button_confirm.disabled = _selected_index == -1

func _on_confirm_pressed() -> void:
	if _selected_index == -1:
		return
	var token := _candidates[_selected_index]
	GameManager.full_bag.erase(token)
	GameManager.purchased_tokens.erase(token)
	GameManager.sacrificed_tokens.append(token)
	GameManager.advance_round()
	get_tree().change_scene_to_file("res://shop_screen.tscn")
