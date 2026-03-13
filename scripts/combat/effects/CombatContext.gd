class_name CombatContext
extends Resource

var cards: Array          # Les cartes sur la ligne
var card_index: int       # Index de la carte actuelle
var is_first: bool        # Est-ce le 1er jeton tiré ?
var is_last: bool         # Est-ce le dernier jeton ?
var result: ResolveResult # Le résultat à modifier
