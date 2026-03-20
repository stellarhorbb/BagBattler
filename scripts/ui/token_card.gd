extends Control

@onready var circle_panel = $CirclePanel
@onready var icon_texture = $CirclePanel/IconTexture

var token_data: TokenResource
var _style: StyleBoxFlat
var _pulse_tween: Tween

func setup(token: TokenResource) -> void:
	token_data = token
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	_style = StyleBoxFlat.new()
	_style.corner_radius_top_left = 70
	_style.corner_radius_top_right = 70
	_style.corner_radius_bottom_left = 70
	_style.corner_radius_bottom_right = 70
	_style.border_width_left = 6
	_style.border_width_top = 6
	_style.border_width_right = 6
	_style.border_width_bottom = 6
	_style.border_color = Color("#FFFFFF")
	match token.token_type:
		TokenResource.TokenType.ATTACK:   _style.bg_color = Color("#E8294A")
		TokenResource.TokenType.DEFENSE:  _style.bg_color = Color("#3D4CE8")
		TokenResource.TokenType.MODIFIER: _style.bg_color = Color("#7B2FE8")
		TokenResource.TokenType.UTILITY:  _style.bg_color = Color("#EAA21C")
		TokenResource.TokenType.HAZARD:   _style.bg_color = Color("#111111")
		_:                                _style.bg_color = Color("#444444")
	circle_panel.add_theme_stylebox_override("panel", _style)
	circle_panel.size = Vector2(110, 110)
	icon_texture.size = Vector2(60, 60)
	icon_texture.position = Vector2(25, 25)
	_load_icon()


func set_streak_pulse(active: bool) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	pivot_offset = size / 2.0
	scale = Vector2.ONE
	if not active:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_interval(0.5)

func set_selected(selected: bool) -> void:
	if selected:
		_style.border_color = Color("000000ff")
		_style.border_width_left = 10
		_style.border_width_top = 10
		_style.border_width_right = 10
		_style.border_width_bottom = 10
	else:
		_style.border_color = Color("#FFFFFF")
		_style.border_width_left = 6
		_style.border_width_top = 6
		_style.border_width_right = 6
		_style.border_width_bottom = 6

func set_inactive(inactive: bool) -> void:
	if inactive:
		_style.bg_color = Color("#4C4C4C")
	else:
		match token_data.token_type:
			TokenResource.TokenType.ATTACK:   _style.bg_color = Color("#E8294A")
			TokenResource.TokenType.DEFENSE:  _style.bg_color = Color("#3D4CE8")
			TokenResource.TokenType.MODIFIER: _style.bg_color = Color("#7B2FE8")
			TokenResource.TokenType.UTILITY:  _style.bg_color = Color("#EAA21C")
			TokenResource.TokenType.HAZARD:   _style.bg_color = Color("#111111")
			_:                                _style.bg_color = Color("#444444")

func _on_hover() -> void:
	if mouse_filter == MOUSE_FILTER_IGNORE:
		return
	TooltipManager.show_token(token_data, global_position, size)

func _on_unhover() -> void:
	TooltipManager.hide_tooltip()

func _load_icon() -> void:
	var icon_map = {
		"strike":      "res://assets/icons/tokens/new/strike.png",
		"guard":       "res://assets/icons/tokens/new/guard.png",
		"rampart":     "res://assets/icons/tokens/new/rampart.png",
		"provocation": "res://assets/icons/tokens/new/provocation.png",
		"skull":       "res://assets/icons/tokens/new/skull.png",
		"heal":        "res://assets/icons/tokens/new/heal.png",
	}
	var key = token_data.token_name.to_lower()
	if icon_map.has(key) and ResourceLoader.exists(icon_map[key]):
		icon_texture.texture = load(icon_map[key])
		icon_texture.modulate = Color(1, 1, 1, 1)
		icon_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		icon_texture.custom_minimum_size = Vector2(52, 52)
