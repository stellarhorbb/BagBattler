class_name BaseEffect
extends Resource

# Chaque effet reçoit le contexte complet du combat
# et modifie le ResolveResult en conséquence
func apply(_context: CombatContext) -> void:
	pass  # Surchargé par chaque effet
