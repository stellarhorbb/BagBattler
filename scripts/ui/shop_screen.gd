extends Control

var reroll_cost: int = 2
var all_shop_tokens: Array[TokenResource] = []

var _font = preload("res://font/LondrinaSolid-Black.ttf")
var _token_card_scene = preload("res://token_card.tscn")
var _relic_card_scene = preload("res://relic_card.tscn")
var _salt_icon = preload("res://assets/icons/ui/salt-icon.png")

@onready var items_row = $ContentVBox/ShopPanel/PanelLayout/ItemsRow
@onready var button_reroll = $ContentVBox/ShopPanel/PanelLayout/RerollRow/ButtonReroll
@onready var button_continue = $ContentVBox/ButtonContinue
@onready var label_salt_total = $SaltHUD/SaltRow/LabelSaltTotal
@onready var player_hp_bar = $StatsBar/CenterStat/PlayerHPBar
@onready var label_player_hp = $StatsBar/CenterStat/LabelPlayerHP
@onready var label_dmg_value = $StatsBar/LeftStat/DmgRow/LabelDmgValue
@onready var label_def_value = $StatsBar/RightStat/DefRow/LabelDefValue
@onready var relic_line = $StatsBar/CenterStat/RelicLine

func _ready() -> void:
	all_shop_tokens = [
		preload("res://resources/tokens/strike.tres"),
		preload("res://resources/tokens/guard.tres"),
		preload("res://resources/tokens/provocation.tres"),
		preload("res://resources/tokens/rampart.tres"),
		preload("res://resources/tokens/frenzy.tres"),
		preload("res://resources/tokens/heal.tres"),
		preload("res://resources/tokens/reckless.tres"),
		preload("res://resources/tokens/resonance.tres"),
		preload("res://resources/tokens/gamble.tres"),
	]
	relic_line.setup()
	_populate_shop()
	_update_display()

func _populate_shop() -> void:
	for child in items_row.get_children():
		child.queue_free()

	# 2 random tokens
	var total_weight = 0.0
	for token in all_shop_tokens:
		total_weight += token.shop_drop_weight

	for _i in 2:
		var roll = randf() * total_weight
		var cumulative = 0.0
		var picked: TokenResource = all_shop_tokens[0]
		for token in all_shop_tokens:
			cumulative += token.shop_drop_weight
			if roll <= cumulative:
				picked = token
				break
		var price := picked.shop_price if picked.shop_price > 0 else roundi(10.0 / picked.shop_drop_weight)
		var icon = _token_card_scene.instantiate()
		var item = _make_item(icon, picked.token_name.to_upper(), price)
		item.get_node("BuyButton").pressed.connect(func(): _on_buy_token(picked, price, item.get_node("BuyButton")))
		items_row.add_child(item)
		icon.setup(picked)

	# 1 random relic
	var shop_relics := [
		[preload("res://resources/relics/crown_of_fool.tres"), RelicCrownOfFool],
		[preload("res://resources/relics/jellyfish.tres"), RelicTrident],
		[preload("res://resources/relics/angel.tres"), RelicAngel],
	]
	var entry = shop_relics[randi() % shop_relics.size()]
	var data: RelicResource = entry[0]
	var relic_class = entry[1]
	var already_owned = GameManager.purchased_relics.any(func(r): return r.relic_data == data)

	var relic_icon = _relic_card_scene.instantiate()
	relic_icon.custom_minimum_size = Vector2(140, 140)
	var relic_item = _make_item(relic_icon, data.relic_name.to_upper(), data.cost)
	var buy_btn = relic_item.get_node("BuyButton")
	buy_btn.disabled = already_owned
	if not already_owned:
		buy_btn.pressed.connect(func(): _on_buy_relic(data, relic_class, buy_btn))
	items_row.add_child(relic_item)
	relic_icon.setup(data)

	_update_reroll_button()

func _make_item(icon_node: Node, item_name: String, price: int) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	icon_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_node)

	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_override("font", _font)
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var style_buy = StyleBoxFlat.new()
	style_buy.bg_color = Color(1, 1, 1, 1)
	style_buy.border_width_left = 2
	style_buy.border_width_top = 2
	style_buy.border_width_right = 2
	style_buy.border_width_bottom = 2
	style_buy.border_color = Color(0, 0, 0, 1)
	style_buy.corner_radius_top_left = 8
	style_buy.corner_radius_top_right = 8
	style_buy.corner_radius_bottom_left = 8
	style_buy.corner_radius_bottom_right = 8

	var style_buy_disabled = StyleBoxFlat.new()
	style_buy_disabled.bg_color = Color(0.4, 0.4, 0.4, 1)
	style_buy_disabled.corner_radius_top_left = 8
	style_buy_disabled.corner_radius_top_right = 8
	style_buy_disabled.corner_radius_bottom_left = 8
	style_buy_disabled.corner_radius_bottom_right = 8

	var btn = Button.new()
	btn.name = "BuyButton"
	btn.text = "BUY"
	btn.custom_minimum_size = Vector2(140, 46)
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 1))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 1))
	btn.add_theme_stylebox_override("normal", style_buy)
	btn.add_theme_stylebox_override("pressed", style_buy)
	btn.add_theme_stylebox_override("hover", style_buy)
	btn.add_theme_stylebox_override("disabled", style_buy_disabled)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn)

	var price_row = HBoxContainer.new()
	price_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	price_row.add_theme_constant_override("separation", 6)
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var price_label = Label.new()
	price_label.text = "%d" % price
	price_label.add_theme_font_override("font", _font)
	price_label.add_theme_font_size_override("font_size", 26)
	price_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var price_icon = TextureRect.new()
	price_icon.texture = _salt_icon
	price_icon.custom_minimum_size = Vector2(20, 20)
	price_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	price_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	price_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	price_row.add_child(price_label)
	price_row.add_child(price_icon)
	vbox.add_child(price_row)

	return vbox

func _on_buy_token(token: TokenResource, price: int, btn: Button) -> void:
	if GameManager.gold < price:
		return
	GameManager.gold -= price
	GameManager.purchased_tokens.append(token)
	GameManager.full_bag.append(token)
	btn.disabled = true
	_update_display()

func _on_buy_relic(data: RelicResource, relic_class: GDScript, btn: Button) -> void:
	if GameManager.gold < data.cost:
		return
	var instance: BaseRelic = relic_class.new()
	if not RelicManager.add_relic(instance):
		return
	GameManager.gold -= data.cost
	GameManager.purchased_relics.append(instance)
	btn.disabled = true
	_update_display()

func _on_reroll_pressed() -> void:
	if GameManager.gold < reroll_cost:
		return
	GameManager.gold -= reroll_cost
	reroll_cost += 2
	_populate_shop()
	_update_display()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://battle_scene.tscn")

func _update_reroll_button() -> void:
	button_reroll.text = "REROLL  %d" % reroll_cost

func _update_display() -> void:
	label_salt_total.text = "%d" % GameManager.gold
	label_dmg_value.text = "%d" % GameManager.base_damage
	label_def_value.text = "%d" % GameManager.base_defense
	player_hp_bar.max_value = GameManager.player_max_hp
	player_hp_bar.value = GameManager.player_current_hp
	label_player_hp.text = "%d/%d" % [GameManager.player_current_hp, GameManager.player_max_hp]
	_update_reroll_button()
