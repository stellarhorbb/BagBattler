extends Control

signal token_dropped(slot_index: int, token: TokenResource)
signal slot_clicked(slot_index: int)

const TokenCardScene := preload("res://token_card.tscn")

var slot_index: int = -1
var _token: TokenResource = null
var _card: Control = null

@onready var bg_panel: Panel = $BgPanel
@onready var border_overlay: Panel = $BorderOverlay
@onready var wave_ring = $WaveRing

var _border_style: StyleBoxFlat

func setup(i: int) -> void:
	slot_index = i
	_border_style = border_overlay.get_theme_stylebox("panel").duplicate()
	border_overlay.add_theme_stylebox_override("panel", _border_style)

func set_effect_state(active: bool, color: Color = Color.WHITE) -> void:
	wave_ring.set_ring(active, color)

func set_streak_active(active: bool, color: Color = Color.WHITE) -> void:
	_border_style.border_color = color if active else Color(0.082, 0.082, 0.082, 1)

func is_empty() -> bool:
	return _token == null

func place_token(token: TokenResource) -> void:
	if not is_empty():
		return
	_token = token
	_card = TokenCardScene.instantiate()
	add_child(_card)
	_card.setup(token)
	_card.pivot_offset = Vector2(70, 70)
	_card.scale = Vector2(1.1, 1.1)
	_card.rotation = -0.07
	var t = _card.create_tween()
	t.set_parallel(true)
	t.tween_property(_card, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(_card, "rotation", 0.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func take_token() -> TokenResource:
	var t := _token
	_token = null
	if _card:
		_card.queue_free()
		_card = null
	return t

func get_token() -> TokenResource:
	return _token

func get_card() -> Control:
	return _card

func pop_card() -> Control:
	var card := _card
	_card = null
	if card:
		remove_child(card)
	return card

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_empty():
			slot_clicked.emit(slot_index)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return is_empty() and data is Dictionary and data.get("type") == "revealed_token"

func _drop_data(_pos: Vector2, data: Variant) -> void:
	place_token(data["token"])
	token_dropped.emit(slot_index, data["token"])
