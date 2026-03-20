extends CanvasLayer

var _relic_tooltip: Control
var _token_tooltip: Control
var _hide_timer: SceneTreeTimer = null
var _enabled := true
var _suppressed_until := 0.0

func _ready() -> void:
	layer = 100

	_relic_tooltip = preload("res://relic_tooltip.tscn").instantiate()
	add_child(_relic_tooltip)
	_relic_tooltip.position = Vector2(-9999, -9999)
	_relic_tooltip.hide()

	_token_tooltip = preload("res://token_tooltip.tscn").instantiate()
	add_child(_token_tooltip)
	_token_tooltip.position = Vector2(-9999, -9999)
	_token_tooltip.hide()

func suppress_briefly(duration: float = 0.5) -> void:
	_suppressed_until = Time.get_ticks_msec() / 1000.0 + duration
	_relic_tooltip.hide()
	_token_tooltip.hide()

func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_relic_tooltip.hide()
		_token_tooltip.hide()
		_hide_timer = null

func show_relic(data: RelicResource, card_global_pos: Vector2, card_size: Vector2) -> void:
	if not _enabled:
		return
	_hide_timer = null
	_token_tooltip.hide()
	_relic_tooltip.setup(data)
	_relic_tooltip.position = Vector2(-9999, -9999)
	_relic_tooltip.show()
	await get_tree().process_frame
	await get_tree().process_frame
	_relic_tooltip.reset_size()
	_reposition(_relic_tooltip, card_global_pos, card_size)

func show_token(data: TokenResource, card_global_pos: Vector2, card_size: Vector2) -> void:
	if not _enabled:
		return
	if Time.get_ticks_msec() / 1000.0 < _suppressed_until:
		return
	_hide_timer = null
	_relic_tooltip.hide()
	_token_tooltip.setup(data)
	_token_tooltip.position = Vector2(-9999, -9999)
	_token_tooltip.show()
	await get_tree().process_frame
	await get_tree().process_frame
	_token_tooltip.reset_size()
	_reposition(_token_tooltip, card_global_pos, card_size)

func hide_tooltip() -> void:
	_hide_timer = get_tree().create_timer(0.12)
	_hide_timer.timeout.connect(func():
		if _hide_timer != null:
			_relic_tooltip.hide()
			_token_tooltip.hide()
			_hide_timer = null
	)

func _reposition(tooltip: Control, card_global_pos: Vector2, card_size: Vector2) -> void:
	if not tooltip.visible:
		return
	var vp := get_viewport().get_visible_rect().size
	var tw := tooltip.size.x if tooltip.size.x > 0 else 520.0
	var th := tooltip.size.y if tooltip.size.y > 50 else 300.0
	var x := card_global_pos.x + card_size.x * 0.5 - tw * 0.5
	var y := card_global_pos.y - th - 20.0
	if y < 8.0:
		y = card_global_pos.y + card_size.y + 20.0
	tooltip.position = Vector2(clamp(x, 8.0, vp.x - tw - 8.0), clamp(y, 8.0, vp.y - th - 8.0))
