extends Control

@onready var button_start = $VBoxContainer/ButtonStart
@onready var button_settings = $VBoxContainer/ButtonSettings
@onready var button_quit = $VBoxContainer/ButtonQuit

func _ready():
	MusicManager.play_menu()
	button_start.pressed.connect(_on_start_pressed)
	button_quit.pressed.connect(_on_quit_pressed)
	_setup_hover(button_start)
	_setup_hover(button_quit)

var _origins := {}

func _setup_hover(btn: Button) -> void:
	btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))

func _on_btn_hover(btn: Button, hovering: bool) -> void:
	if not _origins.has(btn):
		_origins[btn] = btn.position
	var target = _origins[btn] + Vector2(0, -6) if hovering else _origins[btn]
	var t = create_tween()
	t.tween_property(btn, "position", target, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_start_pressed():
	GameManager.reset_run()
	button_start.disabled = true
	MusicManager.stop(1.2)
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://job_selection.tscn")

func _on_quit_pressed():
	get_tree().quit()
