class_name DragController
extends Node

signal drag_dropped(slot_index: int, token: TokenResource)

var _slots: Array[Node] = []
var _holder  # RevealedTokenHolder node
var _card_scene: PackedScene
var _root: CanvasItem  # battle_scene root, used for add_child and get_global_mouse_position

var _dragging := false
var _drag_card: Control = null
var _drag_token: TokenResource = null
var _drag_velocity := Vector2.ZERO
var _prev_mouse_pos := Vector2.ZERO

func setup(slots: Array[Node], holder, card_scene: PackedScene, root: CanvasItem) -> void:
	_slots = slots
	_holder = holder
	_card_scene = card_scene
	_root = root

func is_dragging() -> bool:
	return _dragging

func start_drag(token: TokenResource, origin_pos: Vector2) -> void:
	_drag_token = token
	_dragging = true
	_prev_mouse_pos = _root.get_global_mouse_position()
	_drag_velocity = Vector2.ZERO

	_drag_card = _card_scene.instantiate()
	_root.add_child(_drag_card)
	_drag_card.setup(token)
	_drag_card.z_index = 100
	_drag_card.z_as_relative = false
	_drag_card.pivot_offset = Vector2(70, 70)
	_drag_card.global_position = origin_pos
	_drag_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_holder.set_card_alpha(0.25)

	var t = _drag_card.create_tween()
	t.tween_property(_drag_card, "scale", Vector2(1.08, 1.08), 0.12)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	if not _dragging or _drag_card == null:
		return
	var mouse_pos := _root.get_global_mouse_position()
	var target := mouse_pos - Vector2(70, 70)

	_drag_card.global_position = _drag_card.global_position.lerp(target, min(1.0, 18.0 * delta))

	var frame_vel: Vector2 = (mouse_pos - _prev_mouse_pos) / max(delta, 0.001)
	_drag_velocity = _drag_velocity.lerp(frame_vel, 0.25)
	_prev_mouse_pos = mouse_pos

	var target_rot: float = clamp(_drag_velocity.x * 0.0012, -0.22, 0.22)
	_drag_card.rotation = lerp(_drag_card.rotation, target_rot, 12.0 * delta)

func end_drag() -> void:
	_dragging = false
	if _drag_card == null:
		return

	var card_center := _drag_card.global_position + Vector2(70, 70)
	var drop_slot: Node = null
	for slot in _slots:
		if slot.is_empty():
			var slot_center: Vector2 = slot.global_position + Vector2(70, 70)
			if card_center.distance_to(slot_center) < 90.0:
				drop_slot = slot
				break

	var card := _drag_card
	_drag_card = null

	if drop_slot != null:
		var t = card.create_tween()
		t.set_parallel(true)
		t.tween_property(card, "global_position", drop_slot.global_position, 0.12)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(card, "rotation", 0.0, 0.12)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)
		await t.finished
		card.queue_free()
		_holder.clear()
		drop_slot.place_token(_drag_token)
		var dropped_token := _drag_token
		_drag_token = null
		drag_dropped.emit(drop_slot.slot_index, dropped_token)
	else:
		# Return to holder
		var t = card.create_tween()
		t.set_parallel(true)
		t.tween_property(card, "global_position", _holder.global_position, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(card, "rotation", 0.0, 0.2)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
		await t.finished
		card.queue_free()
		_holder.set_card_alpha(1.0)
		_drag_token = null
