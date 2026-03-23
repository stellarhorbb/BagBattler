extends Control

@onready var label_title: Label = $LabelTitle
@onready var label_subtitle: Label = $LabelSubtitle
@onready var token_row: HBoxContainer = $TokenRow
@onready var button_confirm: Button = $ButtonConfirm

const TOKEN_CARD = preload("res://token_card.tscn")
const FONT_BLACK = preload("res://font/LondrinaSolid-Black.ttf")
const HZD_TOKEN = preload("res://resources/tokens/hazard.tres")
const CARD_SIZE := 110.0

var _target_token: TokenResource = null
var _target_card: Control = null
var _target_name_label: Label = null

func _ready() -> void:
	button_confirm.disabled = true
	button_confirm.text = "NEXT"
	button_confirm.focus_mode = Control.FOCUS_NONE
	button_confirm.pressed.connect(_on_next_pressed)

	label_title.text = "CORRUPTION"
	label_subtitle.text = "THE DEPTHS TAKE WHAT THEY WANT"

	RunHUD.visible = true
	RunHUD.set_info_color(Color.WHITE)
	RunHUD.refresh()

	if not _build_tokens():
		button_confirm.disabled = false
		return

	await get_tree().create_timer(0.6).timeout
	await _vibrate_then_corrupt()

func _build_tokens() -> bool:
	var pool: Array[TokenResource] = []
	for token in GameManager.full_bag:
		if token.token_type != TokenResource.TokenType.HAZARD:
			pool.append(token)
	if pool.is_empty():
		return false
	pool.shuffle()
	var picks := pool.slice(0, min(3, pool.size()))
	_target_token = picks[0]

	for i in picks.size():
		var token: TokenResource = picks[i]
		var is_target := (i == 0)

		# Wrapper Control — HBoxContainer positions this, we animate the card inside
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(CARD_SIZE + 20, CARD_SIZE + 60)
		token_row.add_child(wrapper)

		var card: Control = TOKEN_CARD.instantiate()
		wrapper.add_child(card)
		card.setup(token)
		card.position = Vector2(10, 0)
		card.pivot_offset = Vector2(CARD_SIZE * 0.5, CARD_SIZE * 0.5)

		var name_label := Label.new()
		name_label.text = token.token_name.to_upper()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", FONT_BLACK)
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
		name_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		name_label.offset_top = -44
		wrapper.add_child(name_label)

		if is_target:
			_target_card = card
			_target_name_label = name_label

	return true

func _vibrate_then_corrupt() -> void:
	var elapsed := 0.0
	var duration := 3.0
	while elapsed < duration:
		var progress := elapsed / duration
		var intensity := 4.0 + progress * 16.0
		var t = create_tween()
		t.set_parallel(true)
		t.tween_property(_target_card, "position",
			Vector2(10.0 + randf_range(-intensity, intensity), randf_range(-intensity * 0.4, intensity * 0.4)), 0.04)
		t.tween_property(_target_card, "rotation", randf_range(-0.12, 0.12) * progress, 0.04)
		await t.finished
		elapsed += 0.04

	_target_card.position = Vector2(10, 0)
	_target_card.rotation = 0.0
	await _corrupt()

func _corrupt() -> void:
	if _target_token != null:
		var idx := GameManager.full_bag.find(_target_token)
		if idx != -1:
			GameManager.full_bag[idx] = HZD_TOKEN.duplicate()

	_target_card.setup(HZD_TOKEN)

	_screen_shake(14.0, 0.5)

	if _target_name_label != null:
		_target_name_label.text = "HAZARD"

	# Turn title and subtitle red
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(label_title, "modulate", Color(1.0, 0.15, 0.15, 1.0), 0.15)
	label_subtitle.text = "A TOKEN HAS BEEN CORRUPTED"
	t.tween_property(label_subtitle, "modulate", Color(1.0, 0.15, 0.15, 1.0), 0.15)

	await get_tree().create_timer(0.4).timeout
	button_confirm.disabled = false

func _screen_shake(strength: float, duration: float) -> void:
	var original := position
	var elapsed := 0.0
	while elapsed < duration:
		var decay := 1.0 - (elapsed / duration)
		position = original + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)) * decay
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	position = original

func _on_next_pressed() -> void:
	GameManager.advance_zone()
	get_tree().change_scene_to_file("res://shop_screen.tscn")
