extends Panel

const RelicCardScene := preload("res://relic_card.tscn")

@onready var label_emoji: Label = $LabelEmoji
@onready var icon_texture: TextureRect = $IconTexture
@onready var particles: GPUParticles2D = $Particles

var _relic_data: RelicResource
var _index: int = -1

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

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

func set_index(i: int) -> void:
	_index = i

func _get_drag_data(_pos: Vector2) -> Variant:
	if _index < 0:
		return null
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

func _on_hover() -> void:
	TooltipManager.show_relic(_relic_data, global_position, size)

func _on_unhover() -> void:
	TooltipManager.hide_tooltip()
