extends CanvasLayer

var _tooltip: Control
var _hide_timer: SceneTreeTimer = null

func _ready() -> void:
	layer = 100
	_tooltip = preload("res://relic_tooltip.tscn").instantiate()
	add_child(_tooltip)
	_tooltip.position = Vector2(-9999, -9999)
	_tooltip.hide()

func show_relic(data: RelicResource, card_global_pos: Vector2, card_size: Vector2) -> void:
	_hide_timer = null
	_tooltip.setup(data)
	_tooltip.position = Vector2(-9999, -9999)
	_tooltip.show()
	# Wait one frame for layout, then shrink to content size before repositioning
	await get_tree().process_frame
	_tooltip.reset_size()
	_reposition(card_global_pos, card_size)

func hide_tooltip() -> void:
	_hide_timer = get_tree().create_timer(0.12)
	_hide_timer.timeout.connect(func():
		if _hide_timer != null:
			_tooltip.hide()
			_hide_timer = null
	)

func _reposition(card_global_pos: Vector2, card_size: Vector2) -> void:
	if not _tooltip.visible:
		return
	var vp := get_viewport().get_visible_rect().size
	var tw := _tooltip.size.x if _tooltip.size.x > 0 else 680.0
	var th := _tooltip.size.y if _tooltip.size.y > 50 else 350.0
	var x := card_global_pos.x + card_size.x * 0.5 - tw * 0.5
	var y := card_global_pos.y - th - 20.0
	if y < 8.0:
		y = card_global_pos.y + card_size.y + 20.0
	_tooltip.position = Vector2(clamp(x, 8.0, vp.x - tw - 8.0), clamp(y, 8.0, vp.y - th - 8.0))
