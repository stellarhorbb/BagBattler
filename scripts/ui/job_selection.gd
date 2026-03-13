extends Control

@onready var button_select = $WeaponCards/SwordCard/VBoxContainer/ButtonSelect
@onready var label_composition = $WeaponCards/SwordCard/VBoxContainer/Composition

var selected_job: JobResource

func _ready():
	selected_job = load("res://resources/jobs/knight.tres")
	button_select.pressed.connect(_on_select_pressed)
	update_composition()

func update_composition() -> void:
	var text = ""
	for entry in selected_job.starting_bag:
		var type_name = ""
		match entry.token.token_type:
			TokenResource.TokenType.ATTACK:
				type_name = "⚔️"
			TokenResource.TokenType.DEFENSE:
				type_name = "🛡️"
			TokenResource.TokenType.HAZARD:
				type_name = "💀"
			TokenResource.TokenType.MODIFIER:
				type_name = "🟣"
			TokenResource.TokenType.UTILITY:
				type_name = "🟡"
			TokenResource.TokenType.CLEANSER:
				type_name = "⬜"
		text += "%s %s ×%d\n" % [type_name, entry.token.token_name, entry.count]
	label_composition.text = text

func _on_select_pressed():
	GameManager.selected_job = selected_job
	get_tree().change_scene_to_file("res://battle_scene.tscn")
