extends Node

# Fonction qui s'execute au démarrage de la scène
func _ready():
	print("=== Test du Bag Manager ===")
	print("")
	
	# On charge les jetons de puis les fichiers .tres
	var sword = load("res://resources/tokens/attack.tres")
	var shield = load("res://resources/tokens/defense.tres")
	var skull = load("res://resources/tokens/hazard.tres")

	# On crée le sac
	var bag = BagManager.new()
	add_child(bag)
	
	print("📋 ÉTAPE 1 : Remplissage initial")
	bag.add_tokens(sword, 4)
	bag.add_tokens(shield, 3)
	bag.add_tokens(skull, 2)
	bag.shuffle()
	bag.print_bag()
	
	# 3. Tire TOUS les jetons (vide le sac)
	print("📋 ÉTAPE 2 : On vide complètement le sac")
	for i in 9:
		bag.draw_token()
	bag.print_bag()
	
	# 4. Reset le sac
	print("📋 ÉTAPE 3 : Reset du sac")
	bag.reset_bag()
	bag.print_bag()
	
	# 5. Tire quelques jetons pour vérifier que ça marche
	print("📋 ÉTAPE 4 : Nouveau tirage après reset")
	bag.draw_token()
	bag.draw_token()
	bag.draw_token()
	
	
	print("=== FIN DU TEST ===")
