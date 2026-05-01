class_name Wave
extends Resource

@export var enemy_scene: PackedScene # Qual inimigo vai nascer? (Ex: globin1.tscn)
@export var enemy_count: int = 5     # Quantos desse inimigo vão nascer?
@export var spawn_interval: float = 2.0 # Tempo (em segundos) entre cada nascimento
