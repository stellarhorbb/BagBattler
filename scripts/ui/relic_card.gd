extends Panel

@onready var label_emoji: Label = $LabelEmoji
@onready var particles: GPUParticles2D = $Particles

func setup(relic_data: RelicResource) -> void:
	self_modulate = relic_data.color
	label_emoji.text = relic_data.emoji

func trigger_pulse() -> void:
	particles.emitting = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18)
