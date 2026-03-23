class_name RewardResource
extends Resource

enum RewardType { GOLD, HEAL, PRESSURE_BOOST }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var reward_type: RewardType
@export var rarity: Rarity
@export var value: int
@export var label: String

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
	reward.reward_type = randi() % 3 as RewardType
	_fill_value(reward)
	return reward

static func generate_of_type(type: RewardType) -> RewardResource:
	var reward = generate_random()
	reward.reward_type = type
	_fill_value(reward)
	return reward

static func _fill_value(reward: RewardResource) -> void:
	match reward.rarity:
		Rarity.COMMON:
			match reward.reward_type:
				RewardType.GOLD:           reward.value = 2
				RewardType.HEAL:           reward.value = 8
				RewardType.PRESSURE_BOOST: reward.value = 5
		Rarity.UNCOMMON:
			match reward.reward_type:
				RewardType.GOLD:           reward.value = 4
				RewardType.HEAL:           reward.value = 12
				RewardType.PRESSURE_BOOST: reward.value = 10
		Rarity.RARE:
			match reward.reward_type:
				RewardType.GOLD:           reward.value = 7
				RewardType.HEAL:           reward.value = 20
				RewardType.PRESSURE_BOOST: reward.value = 15
		Rarity.EPIC:
			match reward.reward_type:
				RewardType.GOLD:           reward.value = 10
				RewardType.HEAL:           reward.value = 30
				RewardType.PRESSURE_BOOST: reward.value = 30
		Rarity.LEGENDARY:
			match reward.reward_type:
				RewardType.GOLD:           reward.value = 15
				RewardType.HEAL:           reward.value = 50
				RewardType.PRESSURE_BOOST: reward.value = 50
