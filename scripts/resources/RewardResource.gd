class_name RewardResource
extends Resource

enum RewardType { GOLD, HP_MAX, UPGRADE_DAMAGE, UPGRADE_DEFENSE, HEAL }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var reward_type: RewardType
@export var rarity: Rarity
@export var value: int
@export var label: String

static func generate_with_rarity(forced_rarity: Rarity) -> RewardResource:
	var reward = RewardResource.new()
	reward.rarity = forced_rarity
	reward.reward_type = randi() % 5 as RewardType
	_fill_value(reward)
	return reward

static func _fill_value(reward: RewardResource) -> void:
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
				RewardType.UPGRADE_DAMAGE:  reward.value = 2
				RewardType.UPGRADE_DEFENSE: reward.value = 2
				RewardType.HEAL:            reward.value = 10
		Rarity.RARE:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(10, 14)
				RewardType.HP_MAX:          reward.value = 8
				RewardType.UPGRADE_DAMAGE:  reward.value = 3
				RewardType.UPGRADE_DEFENSE: reward.value = 3
				RewardType.HEAL:            reward.value = 18
		Rarity.EPIC:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(18, 22)
				RewardType.HP_MAX:          reward.value = 12
				RewardType.UPGRADE_DAMAGE:  reward.value = 4
				RewardType.UPGRADE_DEFENSE: reward.value = 4
				RewardType.HEAL:            reward.value = 28
		Rarity.LEGENDARY:
			match reward.reward_type:
				RewardType.GOLD:            reward.value = randi_range(30, 40)
				RewardType.HP_MAX:          reward.value = 18
				RewardType.UPGRADE_DAMAGE:  reward.value = 5
				RewardType.UPGRADE_DEFENSE: reward.value = 5
				RewardType.HEAL:            reward.value = 40

static func generate_random() -> RewardResource:
	var reward = RewardResource.new()
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
	reward.reward_type = _weighted_type()
	_fill_value(reward)
	return reward

static func _weighted_type() -> RewardType:
	var roll := randf() * 100.0
	if roll < 40.0: return RewardType.GOLD
	if roll < 60.0: return RewardType.HEAL
	if roll < 80.0: return RewardType.HP_MAX
	if roll < 90.0: return RewardType.UPGRADE_DAMAGE
	return RewardType.UPGRADE_DEFENSE
