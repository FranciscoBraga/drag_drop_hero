extends Area2D

# Status do inimigo
@export var hp: int = 30
@export var speed: float = 100.0
@export var damage: int = 10

var direction: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("enemy")
	# Conecta o sinal de colisão via código para facilitar
	area_entered.connect(_on_area_entered)

func _process(delta):
	# Movimenta o inimigo continuamente na direção definida pelo Spawner
	position += direction * speed * delta

func _on_area_entered(area: Area2D):
	# Verifica se colidiu com o rei ou com um herói
	if area.is_in_group("king") or area.is_in_group("hero"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		
		# Para este protótipo inicial, o inimigo causa dano e "morre" (ataque kamikaze)
		# Mais para frente podemos adicionar a lógica de parar, bater a cada X segundos, etc.
		queue_free()

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		queue_free() # Inimigo morre
