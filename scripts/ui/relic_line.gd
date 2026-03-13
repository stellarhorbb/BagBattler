extends HBoxContainer

const RelicCardScene := preload("res://relic_card.tscn")

var _cards: Array[Node] = []

func setup() -> void:
	for relic in RelicManager.relics:
		var card := RelicCardScene.instantiate()
		add_child(card)
		card.setup(relic.relic_data)
		_cards.append(card)

func trigger_pulse(index: int) -> void:
	if index >= 0 and index < _cards.size():
		_cards[index].trigger_pulse()
