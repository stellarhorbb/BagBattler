class_name Enemy
extends Node

# Référence à la définition de l'ennemi (son "blueprint")
var enemy_data: EnemyResource

# État actuel en combat
var current_hp: int
var current_intention: String = "attack"
var current_damage: int

# Signal pour informer l'UI quand l'ennemi change
signal hp_changed(new_hp, max_hp)
signal intention_changed(intention_type, damage)
signal enemy_died

# Fonction pour initialiser l'ennemi avec ses données
func setup(data: EnemyResource) -> void:
	enemy_data = data
	current_hp = data.max_hp
	current_damage = data.base_damage
	current_intention = "attack"
	
	# On informe l'UI de l'état initial
	hp_changed.emit(current_hp, enemy_data.max_hp)
	intention_changed.emit(current_intention, current_damage)

# Fonction pour infliger des dégâts à l'ennemi
func take_damage(amount: int) -> void:
	current_hp -= amount
	current_hp = max(current_hp, 0)  # Ne descend pas en dessous de 0
	
	hp_changed.emit(current_hp, enemy_data.max_hp)
	
	if current_hp <= 0:
		enemy_died.emit()
		print("%s est vaincu !" % enemy_data.enemy_name)
		
# Fonction pour préparer la prochaine action (appelée à chaque tour)
func prepare_next_intention() -> void:
	# Pour l'instant, toujours "attack" avec base_damage
	# Plus tard on pourra varier selon enemy_data.intentions
	current_intention = "attack"
	current_damage = enemy_data.base_damage
	
	intention_changed.emit(current_intention, current_damage)
	print("%s prépare: %s (%d dégâts)" % [enemy_data.enemy_name, current_intention, current_damage])
	
	
