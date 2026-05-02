extends Area2D

# Estados possíveis para animação
enum State {IDLE, MOVE, ATTACK, DEATH}
var current_state = State.IDLE

@export var max_health: int = 100
var current_health: int

@export var speed: float = 50.0 # Velocidade de movimento
var current_target = null

@onready var animation_player = $AnimatedSprite2D# Supondo que você criou este nó

func _ready():
	current_health = max_health
	add_to_group("king")
	change_state(State.IDLE)
  


func _process(delta):
	match current_state:
		State.MOVE:
			if current_target and is_instance_valid(current_target):
				# Move em direção ao alvo
				var direction = (current_target.global_position - global_position).normalized()
				position += direction * speed * delta
				
				# Chegou ao alvo ou muito perto
				if global_position.distance_to(current_target.global_position) < 5.0:
					set_target(null)
			else:
				set_target(null)
		State.ATTACK:
			# Lógica de ataque baseada em timer (opcional para o rei, ele pode ser passivo)
			pass

func set_target(target):
	if target == null:
		current_target = null
		change_state(State.IDLE)
	else:
		current_target = target
		change_state(State.MOVE)

func change_state(new_state):
	current_state = new_state
	match new_state:
		State.IDLE: animation_player.play("idle")
		State.MOVE: animation_player.play("walk")
		State.ATTACK: animation_player.play("attack")
		State.DEATH: animation_player.play("death")

func take_damage(amount: int):
	# Não pode receber dano se estiver morto
	if current_state == State.DEATH: return
	
	current_health -= amount
	print("Rei sofreu dano! Vida restante: ", current_health)
	
	if current_health <= 0:
		die()

func die():
	print("O Rei caiu! Vitória dos Monstros!")
	change_state(State.DEATH)
	
	# O Godot avisa magicamente TODOS os nós do grupo "enemy" para rodarem a função "celebrate"
	get_tree().call_group("enemy", "celebrate")
	
	# Espera 3 segundos (para dar tempo de ver os monstros comemorando) antes de reiniciar a fase
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
	
