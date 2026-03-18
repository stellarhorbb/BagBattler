class_name BattleVFX
extends Node

var flash_overlay: ColorRect
var vignette_overlay: ColorRect
var crash_banner: Control
var saved_banner: Control
var _root: Control

func setup(flash: ColorRect, vignette: ColorRect, banner: Control, saved: Control, root: Control) -> void:
	flash_overlay = flash
	vignette_overlay = vignette
	crash_banner = banner
	saved_banner = saved
	_root = root

func trigger_screen_shake(intensity: float = 7.0, duration: float = 0.35) -> void:
	var origin := _root.position
	var steps := 8
	var step_time := duration / steps
	var tween = create_tween()
	for i in steps:
		var factor := 1.0 - float(i) / steps
		var offset := Vector2(
			randf_range(-intensity, intensity) * factor,
			randf_range(-intensity * 0.6, intensity * 0.6) * factor
		)
		tween.tween_property(_root, "position", origin + offset, step_time)
	tween.tween_property(_root, "position", origin, step_time * 0.5)

func trigger_hazard_flash() -> void:
	flash_overlay.modulate.a = 0.4
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.3)

func update_vignette(hazard_count: int) -> void:
	vignette_overlay.visible = hazard_count >= 1

func trigger_crash_effect() -> void:
	var tween = create_tween()
	tween.tween_property(crash_banner, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(1.4)
	tween.tween_property(crash_banner, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	update_vignette(0)

func trigger_saved_effect() -> void:
	var tween = create_tween()
	tween.tween_property(saved_banner, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(1.4)
	tween.tween_property(saved_banner, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	update_vignette(0)
