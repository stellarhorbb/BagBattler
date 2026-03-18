extends Panel

@onready var label_rarity: Label = $LayoutBox/RarityHeader/LabelRarity
@onready var rarity_header: Panel = $LayoutBox/RarityHeader
@onready var icon_texture: TextureRect = $LayoutBox/ContentBox/IconTexture
@onready var label_type_name: Label = $LayoutBox/ContentBox/LabelTypeName
@onready var label_value: Label = $LayoutBox/ContentBox/LabelValue

var _callback: Callable

const RARITY_COLORS = {
	RewardResource.Rarity.COMMON:    Color("454545"),
	RewardResource.Rarity.UNCOMMON:  Color("4a5eaa"),
	RewardResource.Rarity.RARE:      Color("2244ee"),
	RewardResource.Rarity.EPIC:      Color("cc22aa"),
	RewardResource.Rarity.LEGENDARY: Color("cc7700"),
}

const RARITY_NAMES = {
	RewardResource.Rarity.COMMON:    "COMMON",
	RewardResource.Rarity.UNCOMMON:  "UNCOMMON",
	RewardResource.Rarity.RARE:      "RARE",
	RewardResource.Rarity.EPIC:      "EPIC",
	RewardResource.Rarity.LEGENDARY: "LEGENDARY",
}

const TYPE_ICONS = {
	RewardResource.RewardType.UPGRADE_DAMAGE:  "res://assets/icons/ui/attack-icon.png",
	RewardResource.RewardType.UPGRADE_DEFENSE: "res://assets/icons/ui/defense-icon.png",
	RewardResource.RewardType.HP_MAX:          "res://assets/icons/ui/max-health-icon.png",
	RewardResource.RewardType.HEAL:            "res://assets/icons/ui/heal-icon.png",
	RewardResource.RewardType.GOLD:            "res://assets/icons/ui/salt-icon.png",
}

const TYPE_NAMES = {
	RewardResource.RewardType.UPGRADE_DAMAGE:  "BASE ATTACK",
	RewardResource.RewardType.UPGRADE_DEFENSE: "BASE DEFENSE",
	RewardResource.RewardType.HP_MAX:          "MAX HEALTH",
	RewardResource.RewardType.HEAL:            "HEAL",
	RewardResource.RewardType.GOLD:            "SALT",
}

func setup(reward: RewardResource, callback: Callable) -> void:
	_callback = callback

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = RARITY_COLORS[reward.rarity]
	rarity_header.add_theme_stylebox_override("panel", header_style)
	label_rarity.text = RARITY_NAMES[reward.rarity]

	icon_texture.texture = load(TYPE_ICONS[reward.reward_type])
	label_type_name.text = TYPE_NAMES[reward.reward_type]

	match reward.reward_type:
		RewardResource.RewardType.UPGRADE_DAMAGE, RewardResource.RewardType.UPGRADE_DEFENSE, \
		RewardResource.RewardType.HP_MAX, RewardResource.RewardType.HEAL:
			label_value.text = "+%d" % reward.value
		RewardResource.RewardType.GOLD:
			label_value.text = "+%d" % reward.value

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_callback.call()
