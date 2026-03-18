extends Control

signal drag_started(token: TokenResource, origin_pos: Vector2)

const TokenCardScene := preload("res://token_card.tscn")

var _token: TokenResource = null
var _card: Control = null

func reveal(token: TokenResource) -> void:
	_token = token
	_card = TokenCardScene.instantiate()
	add_child(_card)
	_card.setup(token)
	_card.mouse_filter = Control.MOUSE_FILTER_PASS
	visible = true

func clear() -> void:
	_token = null
	if _card:
		_card.queue_free()
		_card = null
	visible = false

func get_token() -> TokenResource:
	return _token

func set_card_alpha(a: float) -> void:
	if _card:
		_card.modulate.a = a

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _token != null:
			drag_started.emit(_token, global_position)
