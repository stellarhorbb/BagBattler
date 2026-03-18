extends Control

@onready var circle_panel = $CirclePanel
@onready var icon_texture = $CirclePanel/IconTexture
@onready var particles = $Particles

var token_data: TokenResource
var _style: StyleBoxFlat

func setup(token: TokenResource) -> void:
	token_data = token
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
		TokenResource.TokenType.HAZARD:   _style.bg_color = Color("#111111")
		_:                                _style.bg_color = Color("#444444")
	circle_panel.add_theme_stylebox_override("panel", _style)
	circle_panel.size = Vector2(140, 140)
	icon_texture.size = Vector2(80, 80)
	icon_texture.position = Vector2(30, 30)
	_load_icon()

func set_effect_state(state: String) -> void:
	match state:
		"none":
			_style.border_color = Color("#FFFFFF")
			_style.border_width_left = 6
			_style.border_width_top = 6
			_style.border_width_right = 6
			_style.border_width_bottom = 6
			particles.emitting = false
		"basic":
			_style.border_color = Color("#FFD700")
			_style.border_width_left = 6
			_style.border_width_top = 6
			_style.border_width_right = 6
			_style.border_width_bottom = 6
			particles.amount = 8
			particles.initial_velocity_min = 15.0
			particles.initial_velocity_max = 40.0
			particles.scale_amount_min = 2.0
			particles.scale_amount_max = 3.5
			particles.emitting = true
		"superior":
			_style.border_color = Color("#FFD700")
			_style.border_width_left = 10
			_style.border_width_top = 10
			_style.border_width_right = 10
			_style.border_width_bottom = 10
			particles.amount = 20
			particles.initial_velocity_min = 30.0
			particles.initial_velocity_max = 70.0
			particles.scale_amount_min = 3.0
			particles.scale_amount_max = 5.5
			particles.emitting = true

func _load_icon() -> void:
	var icon_map = {
		"strike":      "res://assets/icons/tokens/strike-icon.png",
		"guard":       "res://assets/icons/tokens/guard-icon.png",
		"rampart":     "res://assets/icons/tokens/rampart-icon.png",
		"provocation": "res://assets/icons/tokens/provocation-icon.png",
		"hazard":      "res://assets/icons/tokens/skull-icon.png",
	}
	var key = token_data.token_name.to_lower()
	if icon_map.has(key) and ResourceLoader.exists(icon_map[key]):
		icon_texture.texture = load(icon_map[key])
		icon_texture.modulate = Color(1, 1, 1, 1)
		icon_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		icon_texture.custom_minimum_size = Vector2(52, 52)
