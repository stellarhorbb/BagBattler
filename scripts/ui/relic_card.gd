extends Panel

const RelicCardScene := preload("res://relic_card.tscn")

const SELL_PRICE := 3

@onready var label_emoji: Label = $LabelEmoji
@onready var icon_texture: TextureRect = $IconTexture
@onready var particles: GPUParticles2D = $Particles

var _relic_data: RelicResource
var _index: int = -1
var _sell_popup: Control = null

var _font = preload("res://font/LondrinaSolid-Black.ttf")
var _salt_icon = preload("res://assets/icons/ui/salt-icon.png")

func setup(relic_data: RelicResource) -> void:
	_relic_data = relic_data
	if relic_data.icon:
		icon_texture.texture = relic_data.icon
		icon_texture.visible = true
		label_emoji.visible = false
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		self_modulate = relic_data.color
		label_emoji.text = relic_data.emoji

	if not mouse_entered.is_connected(_on_hover):
		mouse_entered.connect(_on_hover)
	if not mouse_exited.is_connected(_on_unhover):
		mouse_exited.connect(_on_unhover)

func set_index(i: int) -> void:
	_index = i

func _get_drag_data(_pos: Vector2) -> Variant:
	if _index < 0:
		return null
	_hide_sell_popup()
	TooltipManager.hide_tooltip()
	var preview := RelicCardScene.instantiate()
	add_child(preview)
	preview.setup(_relic_data)
	remove_child(preview)
	preview.modulate.a = 0.6
	set_drag_preview(preview)
	return { "type": "relic", "index": _index }

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == "relic" and data.get("index") != _index

func _drop_data(_pos: Vector2, data: Variant) -> void:
	RelicManager.reorder(data["index"], _index)
	get_parent().refresh()

func trigger_pulse() -> void:
	particles.emitting = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18)

# ── SELL POPUP ────────────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_instance_valid(_sell_popup):
			_hide_sell_popup()
		else:
			_show_sell_popup()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_sell_popup):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var popup_rect = Rect2(_sell_popup.global_position, _sell_popup.size)
		var card_rect = Rect2(global_position, size)
		if not popup_rect.has_point(event.global_position) and not card_rect.has_point(event.global_position):
			_hide_sell_popup()

func _show_sell_popup() -> void:
	TooltipManager.hide_tooltip()

	var popup = PanelContainer.new()
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.05, 1)
	bg.border_width_left = 3
	bg.border_width_top = 3
	bg.border_width_right = 3
	bg.border_width_bottom = 3
	bg.border_color = Color(1, 1, 1, 1)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	popup.add_theme_stylebox_override("panel", bg)
	popup.z_index = 10

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# Price row
	var price_row = HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 6)
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(price_row)

	var salt_img = TextureRect.new()
	salt_img.texture = _salt_icon
	salt_img.custom_minimum_size = Vector2(22, 22)
	salt_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	salt_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	price_row.add_child(salt_img)

	var price_lbl = Label.new()
	price_lbl.text = str(SELL_PRICE)
	price_lbl.add_theme_font_override("font", _font)
	price_lbl.add_theme_font_size_override("font_size", 24)
	price_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_row.add_child(price_lbl)

	# Sell button
	var sell_btn = Button.new()
	sell_btn.text = "SELL"
	sell_btn.add_theme_font_override("font", _font)
	sell_btn.add_theme_font_size_override("font_size", 22)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.75, 0.1, 0.1, 1)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	sell_btn.add_theme_stylebox_override("normal", btn_style)
	sell_btn.add_theme_stylebox_override("hover", btn_style)
	sell_btn.add_theme_stylebox_override("pressed", btn_style)
	sell_btn.add_theme_color_override("font_color", Color.WHITE)
	sell_btn.pressed.connect(_on_sell)
	vbox.add_child(sell_btn)

	add_child(popup)
	_sell_popup = popup

	# Position above card after one layout frame
	await get_tree().process_frame
	if is_instance_valid(_sell_popup):
		_sell_popup.position = Vector2(
			(size.x - _sell_popup.size.x) / 2.0,
			-_sell_popup.size.y - 6.0
		)

func _hide_sell_popup() -> void:
	if is_instance_valid(_sell_popup):
		_sell_popup.queue_free()
	_sell_popup = null

func _on_sell() -> void:
	var relic = RelicManager.relics[_index]
	_hide_sell_popup()
	RelicManager.remove_relic(relic)
	GameManager.purchased_relics.erase(relic)
	GameManager.gold += SELL_PRICE
	RunHUD.refresh()
	get_parent().refresh()

# ── HOVER ─────────────────────────────────────────────────────────────────────

func _on_hover() -> void:
	if is_instance_valid(_sell_popup):
		return
	TooltipManager.show_relic(_relic_data, global_position, size)

func _on_unhover() -> void:
	TooltipManager.hide_tooltip()
