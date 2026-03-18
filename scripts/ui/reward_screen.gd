extends Control

@onready var label_subtitle = $ContentVBox/LabelSubtitle
@onready var stars_row = $ContentVBox/StarsRow
@onready var reward_container = $ContentVBox/RewardContainer
@onready var label_salt_total = $SaltHUD/SaltRow/LabelSaltTotal
@onready var label_salt_earned = $SaltHUD/LabelSaltEarned
@onready var player_hp_bar = $StatsBar/CenterStat/PlayerHPBar
@onready var label_player_hp = $StatsBar/CenterStat/LabelPlayerHP
@onready var label_dmg_value = $StatsBar/LeftStat/DmgRow/LabelDmgValue
@onready var label_def_value = $StatsBar/RightStat/DefRow/LabelDefValue

var _font = preload("res://font/LondrinaSolid-Black.ttf")
var reward_card_scene = preload("res://reward_card.tscn")

func _ready() -> void:
	var reward = GameManager.calculate_combat_reward()
	GameManager.gold += reward

	_build_stars()
	_build_rewards()
	_update_stats_bar()
	_update_salt_hud(reward)

func _build_stars() -> void:
	var turns = GameManager.turns_played_last_combat
	var star_count = 3 if turns < 5 else (2 if turns <= 10 else 1)
	for child in stars_row.get_children():
		child.queue_free()
	for i in 3:
		var star = Label.new()
		star.text = "★"
		star.add_theme_font_override("font", _font)
		star.add_theme_font_size_override("font_size", 52)
		star.add_theme_color_override("font_color",
			Color(1.0, 0.78, 0.1, 1) if i < star_count else Color(0.35, 0.35, 0.35, 1))
		stars_row.add_child(star)

func _build_rewards() -> void:
	for child in reward_container.get_children():
		child.queue_free()
	for i in 3:
		var r = RewardResource.generate_random()
		var card = reward_card_scene.instantiate()
		reward_container.add_child(card)
		card.setup(r, func(): _on_reward_chosen(r))

func _update_stats_bar() -> void:
	label_dmg_value.text = "%d" % GameManager.base_damage
	label_def_value.text = "%d" % GameManager.base_defense
	player_hp_bar.max_value = GameManager.player_max_hp
	player_hp_bar.value = GameManager.player_current_hp
	label_player_hp.text = "%d/%d" % [GameManager.player_current_hp, GameManager.player_max_hp]

func _update_salt_hud(earned: int) -> void:
	label_salt_total.text = "%d" % GameManager.gold
	label_salt_earned.text = "+%d" % earned

func _on_reward_chosen(reward: RewardResource) -> void:
	match reward.reward_type:
		RewardResource.RewardType.GOLD:
			GameManager.gold += reward.value
		RewardResource.RewardType.HP_MAX:
			var old_max = GameManager.player_max_hp
			GameManager.player_max_hp += reward.value
			if GameManager.player_current_hp == old_max:
				GameManager.player_current_hp = GameManager.player_max_hp
			else:
				GameManager.player_current_hp = min(GameManager.player_current_hp + roundi(reward.value * 0.5), GameManager.player_max_hp)
		RewardResource.RewardType.UPGRADE_DAMAGE:
			GameManager.base_damage += reward.value
		RewardResource.RewardType.UPGRADE_DEFENSE:
			GameManager.base_defense += reward.value
		RewardResource.RewardType.HEAL:
			GameManager.player_current_hp = min(GameManager.player_current_hp + reward.value, GameManager.player_max_hp)

	if GameManager.is_boss_round():
		get_tree().change_scene_to_file("res://sacrifice_screen.tscn")
	else:
		GameManager.advance_round()
		get_tree().change_scene_to_file("res://shop_screen.tscn")
