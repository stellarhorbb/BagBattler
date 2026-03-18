class_name EffectFrenzy
extends BaseEffect

func apply(context: CombatContext) -> void:
	var atk_count := 0
	for card in context.cards:
		if card.token_data.token_type == TokenResource.TokenType.ATTACK:
			atk_count += 1
	context.result.total_attack += GameManager.base_damage * atk_count
	print("⚡ FRENZY : %d tokens ATK → +%d ATK" % [atk_count, GameManager.base_damage * atk_count])
