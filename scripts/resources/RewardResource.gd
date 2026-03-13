class_name RewardResource
extends Resource

enum RewardType { GOLD, HP_MAX, UPGRADE_DAMAGE, UPGRADE_DEFENSE, HEAL }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var reward_type: RewardType
@export var rarity: Rarity
@export var value: int
@export var label: String

static func generate_random() -> RewardResource:
	var reward = RewardResource.new()

	# Roll rarity
	var roll = randf() * 100.0
	if roll < 50.0:
		reward.rarity = Rarity.COMMON
	elif roll < 80.0:
		reward.rarity = Rarity.UNCOMMON
	elif roll < 92.0:
		reward.rarity = Rarity.RARE
	elif roll < 97.0:
		reward.rarity = Rarity.EPIC
	else:
		reward.rarity = Rarity.LEGENDARY

	# Roll type
	reward.reward_type = randi() % 5 as RewardType

	# Set value based on rarity + type
	match reward.rarity:
		Rarity.COMMON:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(3, 5)
				RewardType.HP_MAX:          reward.value = 3
				RewardType.UPGRADE_DAMAGE:  reward.value = 1
				RewardType.UPGRADE_DEFENSE: reward.value = 1
				RewardType.HEAL:            reward.value = 5
		Rarity.UNCOMMON:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(6, 8)
				RewardType.HP_MAX:          reward.value = 5
				RewardType.UPGRADE_DAMAGE:  reward.value = 1
				RewardType.UPGRADE_DEFENSE: reward.value = 2
				RewardType.HEAL:            reward.value = 10
		Rarity.RARE:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(10, 14)
				RewardType.HP_MAX:          reward.value = 8
				RewardType.UPGRADE_DAMAGE:  reward.value = 2
				RewardType.UPGRADE_DEFENSE: reward.value = 3
				RewardType.HEAL:            reward.value = 18
		Rarity.EPIC:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(18, 22)
				RewardType.HP_MAX:          reward.value = 12
				RewardType.UPGRADE_DAMAGE:  reward.value = 3
				RewardType.UPGRADE_DEFENSE: reward.value = 4
				RewardType.HEAL:            reward.value = 28
		Rarity.LEGENDARY:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(30, 40)
				RewardType.HP_MAX:          reward.value = 18
				RewardType.UPGRADE_DAMAGE:  reward.value = 5
				RewardType.UPGRADE_DEFENSE: reward.value = 6
				RewardType.HEAL:            reward.value = 40

	# Build label
	var rarity_name = Rarity.keys()[reward.rarity].capitalize()
	match reward.reward_type:
		RewardType.GOLD:
			reward.label = "💰 %d Gold [%s]" % [reward.value, rarity_name]
		RewardType.HP_MAX:
			reward.label = "❤️ +%d Max HP [%s]" % [reward.value, rarity_name]
		RewardType.UPGRADE_DAMAGE:
			reward.label = "⚔️ +%d Base Damage [%s]" % [reward.value, rarity_name]
		RewardType.UPGRADE_DEFENSE:
			reward.label = "🛡️ +%d Base Defense [%s]" % [reward.value, rarity_name]
		RewardType.HEAL:
			reward.label = "❤️‍🩹 +%d HP\n[%s]" % [reward.value, rarity_name]

	return reward
