extends Control

@onready var button_start = $VBoxContainer/ButtonStart
@onready var button_options = $VBoxContainer/ButtonOptions

func _ready():
	# Connexion du bouton Démarrer
	button_start.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	# On reset la run
	GameManager.reset_run()
	
	# On va vers la sélection d'arme
	get_tree().change_scene_to_file("res://job_selection.tscn")
