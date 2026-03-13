extends Control

var reroll_cost: int = 2
var available_tokens: Array[TokenResource] = []
var token_scenes: Array[Node] = []
var all_shop_tokens: Array[TokenResource] = []

@onready var label_gold = $VBox/LabelGold
@onready var label_reroll_cost = $VBox/BottomBar/LabelRerollCost
@onready var token_container = $VBox/TokenContainer
@onready var button_reroll = $VBox/BottomBar/ButtonReroll
@onready var button_continue = $VBox/BottomBar/ButtonContinue
@onready var label_player_hp = $StatsBar/LabelPlayerHP
@onready var label_base_damage = $StatsBar/LabelBaseDamage
@onready var label_base_defense = $StatsBar/LabelBaseDefense

func _ready() -> void:
	all_shop_tokens = [
		preload("res://resources/tokens/strike.tres"),
		preload("res://resources/tokens/guard.tres"),
		preload("res://resources/tokens/provocation.tres"),
		preload("res://resources/tokens/rampart.tres"),
	]
	button_reroll.pressed.connect(_on_reroll_pressed)
	button_continue.pressed.connect(_on_continue_pressed)
	update_gold_display()
	generate_shop()

func generate_shop() -> void:
	for child in token_container.get_children():
		child.queue_free()
	available_tokens.clear()
	token_scenes.clear()

	var total_weight = 0.0
	for token in all_shop_tokens:
		total_weight += token.shop_drop_weight

	for i in 2:
		var roll = randf() * total_weight
		var cumulative = 0.0
		var picked: TokenResource = all_shop_tokens[0]
		for token in all_shop_tokens:
			cumulative += token.shop_drop_weight
			if roll <= cumulative:
				picked = token
				break
		available_tokens.append(picked)

		var price = roundi(10.0 / picked.shop_drop_weight)

		var card = Panel.new()
		var vbox = VBoxContainer.new()
		var label_name = Label.new()
		var label_price = Label.new()
		var buy_button = Button.new()

		label_name.text = picked.token_name
		label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_price.text = "%d 💰" % price
		label_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		buy_button.text = "Buy"

		vbox.add_child(label_name)
		vbox.add_child(label_price)
		vbox.add_child(buy_button)
		card.add_child(vbox)
		card.custom_minimum_size = Vector2(200, 150)
		token_container.add_child(card)
		token_scenes.append(card)

		var token_ref = picked
		var price_ref = price
		buy_button.pressed.connect(func(): _on_buy_pressed(token_ref, price_ref, card))

func _on_buy_pressed(token: TokenResource, price: int, card: Node) -> void:
	if GameManager.gold >= price:
		GameManager.gold -= price
		GameManager.purchased_tokens.append(token)
		for child in card.get_children():
			child.queue_free()
		card.modulate = Color(0.5, 0.5, 0.5)
		update_gold_display()
	else:
		print("Not enough gold")

func _on_reroll_pressed() -> void:
	if GameManager.gold >= reroll_cost:
		GameManager.gold -= reroll_cost
		reroll_cost += 2
		generate_shop()
		update_gold_display()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://battle_scene.tscn")

func update_gold_display() -> void:
	label_gold.text = "💰 %d" % GameManager.gold
	label_reroll_cost.text = "Reroll: %d 💰" % reroll_cost
	label_player_hp.text = "HP: %d / %d" % [GameManager.player_current_hp, GameManager.player_max_hp]
	label_base_damage.text = "⚔️ Base DMG: %d" % GameManager.base_damage
	label_base_defense.text = "🛡️ Base DEF: %d" % GameManager.base_defense
