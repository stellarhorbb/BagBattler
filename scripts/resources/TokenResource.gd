class_name TokenResource
extends Resource

# Types de jetons possibles, enum est comme un menu déroulant avec des choix possibles
enum TokenType {
	ATTACK, # Fait des dégats
	DEFENSE, # Génère du bouclier
	MODIFIER,
	UTILITY,
	CLEANSER,
	HAZARD, # Danger
}

enum TokenEffect {
	NONE,
	PROVOCATION,  # Réduit les dégâts ennemis (-25%, ou -75% si 1er tiré)
	RAMPART,      # Base Defense ×2 uniquement si dernier jeton exécuté
}

# Les propriétés de jetons
@export var token_name: String = "Token" # Variable visible dans l'éditeur, avec son nom + valeur par défaut
@export var token_type: TokenType = TokenType.ATTACK # Le type de jeton + valeur par défault
@export var effect: TokenEffect = TokenEffect.NONE
@export var description: String = ""
@export var value: int = 1 # La valeur du jeton (nombre entier) + valeur par défault
@export var weight: float = 1 # Le poid du jeton dans le sac par défaut
@export var shop_drop_weight: float = 1.0
