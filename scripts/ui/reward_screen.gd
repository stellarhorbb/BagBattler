extends Control

@onready var salt_icons_row: HBoxContainer = $ContentVBox/SaltSection/SaltIconsRow
@onready var reward_container: HBoxContainer = $ContentVBox/RewardContainer
@onready var label_choose: Label = $ContentVBox/LabelChoose

var _salt_icon_tex = preload("res://assets/icons/ui/salt-icon.png")
var _reward_card_scene = preload("res://reward_card.tscn")

var _salt_reward: int = 0
var _reward_chosen := false

func _ready() -> void:
	RelicManager.trigger_reward_screen()
	_salt_reward = GameManager.calculate_combat_reward()
	label_choose.modulate.a = 0.0

	_build_rewards()
	_build_salt_icons()

	RunHUD.visible = true
	RunHUD.set_info_color(Color.WHITE)
	RunHUD.refresh()

	_animate_salt()

func _build_rewards() -> void:
	for child in reward_container.get_children():
		child.queue_free()
	var salt = RewardResource.generate_of_type(RewardResource.RewardType.GOLD)
	var other = RewardResource.generate_random()
	while other.reward_type == RewardResource.RewardType.GOLD:
		other = RewardResource.generate_random()
	var rewards = [salt, other]
	rewards.shuffle()
	for r in rewards:
		var card = _reward_card_scene.instantiate()
		reward_container.add_child(card)
		card.setup(r, func(): _on_reward_chosen(r))

func _build_salt_icons() -> void:
	for child in salt_icons_row.get_children():
		child.queue_free()
	for i in _salt_reward:
		var icon = TextureRect.new()
		icon.texture = _salt_icon_tex
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.pivot_offset = Vector2(16, 16)
		icon.rotation_degrees = randf_range(-20.0, 20.0)
		icon.modulate.a = 0.0
		salt_icons_row.add_child(icon)

func _animate_salt() -> void:
	var icons = salt_icons_row.get_children()
	if icons.is_empty():
		_show_cards()
		return

	for i in icons.size():
		var icon: TextureRect = icons[i]
		var t = create_tween()
		t.tween_interval(i * 0.18)
		t.tween_property(icon, "modulate:a", 1.0, 0.12)
		t.tween_callback(func():
			GameManager.add_gold(1)
			RunHUD.refresh()
			_tilt_salt_counter()
		)

	var total_time := (icons.size() - 1) * 0.18 + 0.12 + 0.5
	var seq = create_tween()
	seq.tween_interval(total_time)
	seq.tween_callback(_show_cards)

func _tilt_salt_counter() -> void:
	var lbl = RunHUD.label_gold
	lbl.pivot_offset = lbl.size / 2.0
	var t = create_tween()
	t.tween_property(lbl, "rotation_degrees", randf_range(-12.0, 12.0), 0.07).set_trans(Tween.TRANS_SINE)
	t.tween_property(lbl, "rotation_degrees", 0.0, 0.15).set_trans(Tween.TRANS_SPRING)

func _show_cards() -> void:
	var tween = create_tween()
	tween.tween_property(label_choose, "modulate:a", 1.0, 0.3)

func _on_reward_chosen(reward: RewardResource) -> void:
	if _reward_chosen:
		return
	_reward_chosen = true

	match reward.reward_type:
		RewardResource.RewardType.GOLD:
			GameManager.add_gold(reward.value)
		RewardResource.RewardType.HEAL:
			var heal_amount := roundi(GameManager.player_max_hp * reward.value / 100.0)
			GameManager.player_current_hp = min(GameManager.player_current_hp + heal_amount, GameManager.player_max_hp)
		RewardResource.RewardType.PRESSURE_BOOST:
			GameManager.pending_pressure_boost += reward.value / 100.0

	if GameManager.is_boss_zone():
		get_tree().change_scene_to_file("res://sacrifice_screen.tscn")
	else:
		GameManager.advance_zone()
		get_tree().change_scene_to_file("res://shop_screen.tscn")
