class_name BattleVFX
extends Node

var flash_overlay: ColorRect
var vignette_overlay: ColorRect
var crash_banner: Control

func setup(flash: ColorRect, vignette: ColorRect, banner: Control) -> void:
	flash_overlay = flash
	vignette_overlay = vignette
	crash_banner = banner

func trigger_hazard_flash() -> void:
	flash_overlay.modulate.a = 0.4
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.3)

func update_vignette(hazard_count: int) -> void:
	vignette_overlay.visible = hazard_count >= 1

func trigger_crash_effect() -> void:
	flash_overlay.modulate.a = 0.8
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.5)
	crash_banner.visible = true
	await get_tree().create_timer(2.0).timeout
	crash_banner.visible = false
	update_vignette(0)
