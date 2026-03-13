extends Panel

@onready var label_icon = $VBoxContainer/LabelIcon
@onready var label_name = $VBoxContainer/LabelName
@onready var label_value = $VBoxContainer/LabelValue

var token_data: TokenResource

func setup(token: TokenResource) -> void:
	token_data = token
	label_name.text = token.token_name
	label_value.text = ""

	match token.token_type:
		TokenResource.TokenType.ATTACK:
			label_icon.text = "⚔️"
			self_modulate = Color("ce002dff")
		TokenResource.TokenType.DEFENSE:
			label_icon.text = "🛡️"
			self_modulate = Color("004397ff")
		TokenResource.TokenType.HAZARD:
			label_icon.text = "💀"
			self_modulate = Color("000000ff")
		TokenResource.TokenType.MODIFIER:
			label_icon.text = "🟣"
			self_modulate = Color("6a0dadff")
		TokenResource.TokenType.UTILITY:
			label_icon.text = "🟡"
			self_modulate = Color("ffd700ff")
		TokenResource.TokenType.CLEANSER:
			label_icon.text = "⬜"
			self_modulate = Color("e0e0e0ff")
