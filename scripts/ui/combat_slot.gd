extends Control

signal token_dropped(slot_index: int, token: TokenResource)

const TokenCardScene := preload("res://token_card.tscn")

var slot_index: int = -1
var _token: TokenResource = null
var _card: Control = null

@onready var bg_panel: Panel = $BgPanel

func setup(i: int) -> void:
	slot_index = i

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

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return is_empty() and data is Dictionary and data.get("type") == "revealed_token"

func _drop_data(_pos: Vector2, data: Variant) -> void:
	place_token(data["token"])
	token_dropped.emit(slot_index, data["token"])
