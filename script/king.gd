extends Area2D

# Status básicos para o protótipo
@export var max_health: int = 100
var current_health: int

func _ready():
	current_health = max_health
	# Garante que o Rei está no grupo correto para ser identificado pelos inimigos
	add_to_group("king")

func take_damage(amount: int):
	current_health -= amount
	print("Rei sofreu dano! Vida restante: ", current_health)
	
	if current_health <= 0:
		die()

func die():
	print("O Rei caiu! Game Over.")
	# Reinicia a fase atual
	get_tree().reload_current_scene()
