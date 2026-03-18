class_name BattleVFX
extends Node

var flash_overlay: ColorRect
var vignette_overlay: ColorRect
var crash_banner: Control
var saved_banner: Control

func setup(flash: ColorRect, vignette: ColorRect, banner: Control, saved: Control) -> void:
	flash_overlay = flash
	vignette_overlay = vignette
	crash_banner = banner
	saved_banner = saved

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
