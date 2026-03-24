class_name RelicSaltMerchant
extends BaseRelic

func _init() -> void:
	relic_data = preload("res://resources/relics/salt_merchant.tres")

func on_reward_screen() -> void:
	GameManager.add_gold(5)
