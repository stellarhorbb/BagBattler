extends HBoxContainer

const RelicCardScene := preload("res://relic_card.tscn")

var _cards: Array[Node] = []

func setup() -> void:
	for i in RelicManager.relics.size():
		var card := RelicCardScene.instantiate()
		add_child(card)
		card.setup(RelicManager.relics[i].relic_data)
		card.set_index(i)
		_cards.append(card)

func refresh() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	setup()

func trigger_pulse(index: int) -> void:
	if index >= 0 and index < _cards.size():
		_cards[index].trigger_pulse()
