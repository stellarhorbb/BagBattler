extends Panel

@onready var label_rarity = $VBoxContainer/LabelRarity
@onready var label_type = $VBoxContainer/LabelType
@onready var label_value = $VBoxContainer/LabelValue
@onready var label_rarity_name = $VBoxContainer/LabelRarityName

var _callback: Callable

const RARITY_COLORS = {
	RewardResource.Rarity.COMMON:    Color("666666"),
	RewardResource.Rarity.UNCOMMON:  Color("2d9e2d"),
	RewardResource.Rarity.RARE:      Color("1a6ecf"),
	RewardResource.Rarity.EPIC:      Color("7b2fbf"),
	RewardResource.Rarity.LEGENDARY: Color("cf7a1a"),
}

func setup(reward: RewardResource, callback: Callable) -> void:
	_callback = callback

	match reward.reward_type:
		RewardResource.RewardType.GOLD:
			label_type.text = "💰"
			label_value.text = "%d" % reward.value
		RewardResource.RewardType.HP_MAX:
			label_type.text = "❤️"
			label_value.text = "+%d" % reward.value
		RewardResource.RewardType.UPGRADE_DAMAGE:
			label_type.text = "⚔️"
			label_value.text = "+%d" % reward.value
		RewardResource.RewardType.UPGRADE_DEFENSE:
			label_type.text = "🛡️"
			label_value.text = "+%d" % reward.value
		RewardResource.RewardType.HEAL:
			label_type.text = "❤️"
			label_value.text = "+%d HP" % reward.value

	var rarity_name = RewardResource.Rarity.keys()[reward.rarity].capitalize()
	label_rarity.text = rarity_name

	var type_name: String
	match reward.reward_type:
		RewardResource.RewardType.GOLD:           type_name = "Gold"
		RewardResource.RewardType.HP_MAX:         type_name = "Max HP"
		RewardResource.RewardType.UPGRADE_DAMAGE: type_name = "Base Damage"
		RewardResource.RewardType.UPGRADE_DEFENSE:type_name = "Base Defense"
		RewardResource.RewardType.HEAL:           type_name = "Heal"
	label_rarity_name.text = type_name

	var style = StyleBoxFlat.new()
	style.bg_color = RARITY_COLORS[reward.rarity]
	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_callback.call()
