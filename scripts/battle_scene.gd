extends Control

# Références UI existantes
@onready var label_drawn_token = $LabelDrawnToken
@onready var button_draw = $ButtonDraw
@onready var button_execute = $ButtonExecute
@onready var button_reset = $ButtonReset
@onready var combat_line = $CombatLine 
@onready var label_attack_total = $LabelAttackTotal
@onready var label_defense_total = $LabelDefenseTotal
@onready var label_hazard_warning = $LabelHazardWarning
@onready var button_next = $ButtonNext
@onready var button_back_to_menu = $ButtonBackToMenu

# Références UI Ennemi
@onready var label_enemy_name = $EnemyZone/LabelEnemyName
@onready var label_enemy_hp = $EnemyZone/LabelEnemyHP
@onready var label_enemy_intention = $EnemyZone/LabelEnemyIntention

# Références UI Joueur
@onready var label_player_hp = $PlayerHPZone/LabelPlayerHP
@onready var bag_inspector = $BagInspector

# Scène du jeton virtuel
var token_card_scene = preload("res://token_card.tscn")

# Gestionnaire de sac
var bag_manager = BagManager

# L'ennemi actuel
var current_enemy: Enemy

# HP du joueur (AJOUTE CES LIGNES)
var player_max_hp: int = 20
var player_current_hp: int = 20

func _ready():
	# Création du BagManager
	bag_manager = BagManager.new()
	add_child(bag_manager)
	var job = GameManager.selected_job
	if job == null:
		job = load("res://resources/jobs/knight.tres")

	for entry in job.starting_bag:
		bag_manager.add_tokens(entry.token, entry.count)	

	# Création de l'ennemi
	setup_enemy()
	
	# Connexion des boutons
	button_draw.pressed.connect(_on_button_draw_pressed)
	button_execute.pressed.connect(_on_button_execute_pressed)
	button_reset.pressed.connect(_on_button_reset_pressed)
	
	# Mise à jour de l'affichage
	bag_inspector.setup(bag_manager)
	update_player_hp()
	bag_inspector.refresh()

# Fonction pour créer et configurer l'entité ennemie
func setup_enemy() -> void:
	var stats = GameManager.get_current_stats()
	
	current_enemy = Enemy.new()
	add_child(current_enemy)
	
	# Crée une EnemyResource à la volée depuis les stats du round
	var enemy_data = EnemyResource.new()
	enemy_data.enemy_name = "The Entity"
	enemy_data.max_hp = stats.hp
	enemy_data.base_damage = stats.atk
	
	current_enemy.setup(enemy_data)
	current_enemy.hp_changed.connect(_on_enemy_hp_changed)
	current_enemy.intention_changed.connect(_on_enemy_intention_changed)
	current_enemy.enemy_died.connect(_on_enemy_died)
	
	# Affichage
	var ante = GameManager.get_current_ante()
	var round_in_ante = GameManager.get_round_in_ante()
	label_enemy_name.text = "Ante %d — Round %d" % [ante, round_in_ante]
	if GameManager.is_boss_round():
		label_enemy_name.text += " ★ BOSS"
	label_enemy_hp.text = "HP: %d / %d" % [stats.hp, stats.hp]
	label_enemy_intention.text = "⚔️ %d" % stats.atk

# Fonction appelée quand on clique sur "Tirer un jeton"
func _on_button_draw_pressed():
	var token = bag_manager.draw_token()
	
	if token != null:
		var type_name = TokenResource.TokenType.keys()[token.token_type]
		label_drawn_token.text = "Dernier jeton tiré: %s (%s, Valeur: %d)" % [token.token_name, type_name, token.value]
		
		# Crée une carte visuelle et l'ajoute à la ligne
		var card = token_card_scene.instantiate()
		combat_line.add_child(card)
		card.setup(token)
		
		# Met à jour l'affichage
		update_ui()
		
		# NOUVEAU : Vérification immédiate du Crash
		var hazard_count = 0
		for c in combat_line.get_children():
			var icon = c.get_node("VBoxContainer/LabelIcon").text
			if icon == "💀":
				hazard_count += 1
		
		# Si 2 Hazards ou plus → CRASH IMMÉDIAT !
		if hazard_count >= 2:
			print("💥 CRASH IMMÉDIAT ! Le joueur est stunné !")
			label_drawn_token.text = "💥 CRASH ! Tour perdu, vous prenez tous les dégâts !"
			
			# Le joueur prend TOUS les dégâts ennemis (pas de défense)
			var incoming_damage = current_enemy.current_damage
			print("💀 Dégâts reçus sans défense : %d" % incoming_damage)
			
			player_current_hp -= incoming_damage
			player_current_hp = max(player_current_hp, 0)
			update_player_hp()
			
			# Vérifie si le joueur est mort
			if player_current_hp <= 0:
				print("💀 DÉFAITE ! Le joueur est mort !")
				label_drawn_token.text = "💀 DÉFAITE ! Vous avez été vaincu..."
				button_draw.disabled = true
				button_execute.disabled = true
				button_next.visible = false
				button_back_to_menu.visible = true
				button_back_to_menu.disabled = false
				return
			
			# L'ennemi prépare sa prochaine intention
			current_enemy.prepare_next_intention()
			
			# Nettoyage automatique de la ligne
			for child in combat_line.get_children():
				bag_manager.bag.append(child.token_data)
				child.queue_free()
			
			# Mélange du sac
			bag_manager.shuffle()
			update_ui()
			
			print("=== FIN DU TOUR (CRASH) ===")
			print("")
	else:
		label_drawn_token.text = "⚠️ Le sac est vide !"
		update_ui()

# Fonction appelée quand on clique sur "EXÉCUTER"
func _on_button_execute_pressed():
	print("=== PHASE D'EXÉCUTION ===")
	
	var cards = combat_line.get_children()
	var result = TokenEffectResolver.resolve(cards)
	
	# Dégâts au joueur
	print("Joueur inflige %d dégâts à l'ennemi" % result.total_attack)
	current_enemy.take_damage(result.total_attack)
	
	if current_enemy.current_hp > 0:
		var base_damage = current_enemy.current_damage
		var modified_damage = roundi(base_damage * result.damage_multiplier)
		var incoming_damage = max(0, modified_damage - result.total_defense)
		
		print("Ennemi attaque pour %d (défense: %d) = %d dégâts reçus" % [modified_damage, result.total_defense, incoming_damage])
		
		player_current_hp -= incoming_damage
		player_current_hp = max(player_current_hp, 0)
		update_player_hp()
		
		if player_current_hp <= 0:
			print("💀 DÉFAITE !")
			label_drawn_token.text = "💀 DÉFAITE ! Vous avez été vaincu..."
			button_draw.disabled = true
			button_execute.disabled = true
			button_next.visible = false
			button_back_to_menu.visible = true
			button_back_to_menu.disabled = false
			return
		
		current_enemy.prepare_next_intention()
	
	# Nettoyage et remise des jetons
	for card in cards:
		bag_manager.bag.append(card.token_data)
	
	for child in combat_line.get_children():
		child.queue_free()
	
	bag_manager.shuffle()
	print("=== FIN DU TOUR ===")
	print("")
	update_ui()
	
# Fonction appelée quand on clique sur "Reset"
func _on_button_reset_pressed():
	bag_manager.reset_bag()
	label_drawn_token.text = "Dernier jeton tiré : - "
	
	# Réactive les boutons 
	button_draw.disabled = false
	button_execute.disabled = false
	
	# Reset les HP du joueur
	player_current_hp = player_max_hp
	update_player_hp()
	
	for child in combat_line.get_children():
		child.free()
	
	if current_enemy:
		current_enemy.queue_free()
	setup_enemy()
	
	update_ui()

# Mise à jour de l'affichage du sac
func update_ui():
	update_combat_line_totals()
	bag_inspector.refresh()
	
# Met à jour l'affichage des HP du joueur
func update_player_hp() -> void:
	label_player_hp.text = "HP: %d / %d" % [player_current_hp, player_max_hp]
	
	# Change la couleur selon l'état de santé
	if player_current_hp <= 0:
		label_player_hp.modulate = Color(0.5, 0.5, 0.5)  # Gris si mort
	elif player_current_hp <= player_max_hp * 0.3:
		label_player_hp.modulate = Color(1, 0.3, 0.3)  # Rouge foncé si critique
	else:
		label_player_hp.modulate = Color(1, 0.5, 0.5)  # Rouge normal

# Calcule et affiche les totaux de la ligne de combat
func update_combat_line_totals():
	var cards = combat_line.get_children()
	
	if cards.is_empty():
		label_attack_total.text = "⚔️ 0"
		label_defense_total.text = "🛡️ 0"
		label_hazard_warning.text = ""
		label_enemy_intention.text = "⚔️ %d" % current_enemy.current_damage
		label_enemy_intention.modulate = Color(1, 0.39, 0.39)  # Rouge normal
		return
	
	var result = TokenEffectResolver.resolve(cards)
	
	# Totaux joueur
	label_attack_total.text = "⚔️ %d" % result.total_attack
	label_defense_total.text = "🛡️ %d" % result.total_defense
	
	# Dégâts ennemis modifiés dynamiquement
	var modified_damage = roundi(current_enemy.current_damage * result.damage_multiplier)
	if result.damage_multiplier < 1.0:
		label_enemy_intention.text = "⚔️ %d → %d 🟣" % [current_enemy.current_damage, modified_damage]
		label_enemy_intention.modulate = Color(0.3, 1, 0.3)  # Vert = bonne nouvelle !
	else:
		label_enemy_intention.text = "⚔️ %d" % current_enemy.current_damage
		label_enemy_intention.modulate = Color(1, 0.39, 0.39)  # Rouge normal
	
	# Hazards
	var hazard_count = 0
	for card in cards:
		if card.token_data.token_type == TokenResource.TokenType.HAZARD:
			hazard_count += 1
	
	if hazard_count == 0:
		label_hazard_warning.text = ""
	elif hazard_count == 1:
		label_hazard_warning.text = "⚠️ 1 Hazard - Attention!"
	else:
		label_hazard_warning.text = "💀 CRASH! (%d Hazards)" % hazard_count

# Callbacks pour les signaux de l'ennemi
func _on_enemy_hp_changed(new_hp: int, max_hp: int) -> void:
	label_enemy_hp.text = "HP: %d / %d" % [new_hp, max_hp]

func _on_enemy_intention_changed(_intention_type: String, damage: int) -> void:
	label_enemy_intention.text = "⚔️ Attaque: %d" % damage

func _on_enemy_died() -> void:
	label_drawn_token.text = "🎉 VICTOIRE ! L'ennemi est vaincu !"
	print("=== COMBAT TERMINÉ : VICTOIRE ===")
	
	# Désactive les boutons de jeu
	button_draw.disabled = true
	button_execute.disabled = true
	
	# Affiche le bouton "SUITE"
	button_next.visible = true
	button_next.disabled = false 
	
# Fonction appelée quand on clique sur "SUITE"
# Fonction appelée quand on clique sur "SUITE"
func _on_button_next_pressed():
	print("=== ROUND SUIVANT ===")
	print("Round actuel : %d (Ante %d — Round %d)" % [
		GameManager.current_round,
		GameManager.get_current_ante(),
		GameManager.get_round_in_ante()
	])
	
	GameManager.advance_round()
	
	print("Nouveau round : %d (Ante %d — Round %d)" % [
		GameManager.current_round,
		GameManager.get_current_ante(),
		GameManager.get_round_in_ante()
	])
	if GameManager.is_boss_round():
		print("⚠️ Prochain round = BOSS !")
	print("")
	
	get_tree().reload_current_scene()

# Fonction appelée quand on clique sur "RETOUR AU MENU"
func _on_button_back_to_menu_pressed():
	# Reset la run
	GameManager.reset_run()
	
	# Retour au menu principal
	get_tree().change_scene_to_file("res://main_menu.tscn")
