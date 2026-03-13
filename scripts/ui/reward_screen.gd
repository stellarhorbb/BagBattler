extends Control

@onready var label_efficiency = $VBox/LabelEfficiency
@onready var label_gold_earned = $VBox/LabelGoldEarned
@onready var label_gold_total = $VBox/LabelGoldTotal
@onready var reward_container = $VBox/RewardContainer
@onready var button_continue = $VBox/ButtonContinue
@onready var label_player_hp = $StatsBar/LabelPlayerHP
@onready var label_base_damage = $StatsBar/LabelBaseDamage
@onready var label_base_defense = $StatsBar/LabelBaseDefense

var reward_card_scene = preload("res://reward_card.tscn")

func update_stats_bar() -> void:
	label_player_hp.text = "HP: %d / %d" % [GameManager.player_current_hp, GameManager.player_max_hp]
	label_base_damage.text = "⚔️ Base DMG: %d" % GameManager.base_damage
	label_base_defense.text = "🛡️ Base DEF: %d" % GameManager.base_defense

func _ready() -> void:
	var reward = GameManager.calculate_combat_reward()
	GameManager.gold += reward

	var turns = GameManager.turns_played_last_combat
	if turns < 5:
		label_efficiency.text = "⭐⭐⭐ Efficient!"
	elif turns <= 10:
		label_efficiency.text = "⭐⭐ Good"
	else:
		label_efficiency.text = "⭐ Slow..."

	label_gold_earned.text = "+ %d gold" % reward
	label_gold_total.text = "Total: %d gold" % GameManager.gold

	update_stats_bar()
	button_continue.visible = false
	for i in 3:
		var r = RewardResource.generate_random()
		var card = reward_card_scene.instantiate()
		reward_container.add_child(card)
		card.setup(r, func(): _on_reward_chosen(r))

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

	_on_continue_pressed()

func _on_continue_pressed() -> void:
	GameManager.advance_round()
	get_tree().change_scene_to_file("res://shop_screen.tscn")
