extends Node2D

@export var max_health: int = 200
var current_health: int

# Sinal para informar quando a porta for destruída
signal gate_broken

@onready var sprite = $StaticBody2D/Sprite2D

func _ready():
	current_health = max_health
	add_to_group("gate")
	
	# Posicione a porta de forma que o Rei fique ATRÁS dela na cena Main

func receive_damage(amount: int):
	current_health -= amount
	print("Porta do Castelo recebeu dano! Vida restante: ", current_health)
	
	if current_health <= 0:
		gate_break()

func gate_break():
	print("A PORTA DO CASTELO FOI DESTRUÍDA!")
	emit_signal("gate_broken")
	
	# Mais para frente podemos adicionar animação de quebra
	# Por enquanto, apenas esconde o sprite
	sprite.visible = false
	
	# Remove a porta do grupo, assim os inimigos saberão que ela não é mais alvo
	remove_from_group("gate")
	
	# Desativa a colisão da porta para os inimigos passarem
	$StaticBody2D/CollisionShape2D.disabled = true
