class_name EnemyResource
extends Resource

# Identité
@export var enemy_name: String = "The Entity"
@export var sprite: Texture2D

# Stats de base
@export var max_hp: int = 30
@export var base_damage: int = 5

# Mutations actives sur ce round
@export var mutations: int = 0
@export var is_boss: bool = false

# Intention (ce que l'entité prépare ce tour)
@export var intentions: Array[String] = ["attack"]
