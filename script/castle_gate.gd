extends Node2D

@export var max_health: int = 200
var current_health: int

# Sinal para informar quando a porta for destruída
signal gate_broken
var is_broken: bool = false 

@onready var sprite = $Sprite2D

func _ready():
	current_health = max_health
	add_to_group("gate")
	
	# Posicione a porta de forma que o Rei fique ATRÁS dela na cena Main

func receive_damage(amount: int):
	current_health -= amount
	
	if current_health <= 0:
		gate_break()

func gate_break():
	if is_broken: return
	is_broken = true
	
	emit_signal("gate_broken")
	# Esconde a imagem da porta
	$Sprite2D.visible = false
	# IMPORTANTE: NÃO removemos do grupo "gate"! 
	# Queremos que os inimigos continuem andando até ela.
	# Se você tiver um CollisionShape2D para bloquear movimento físico (CharacterBody), desative-o:
	# $StaticBody2D/CollisionShape2D.disabled = true
