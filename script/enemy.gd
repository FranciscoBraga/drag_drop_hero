extends Area2D

# Estados possíveis para animação
enum State {IDLE, MOVE, ATTACK, DEATH}
var current_state = State.MOVE # Inimigo nasce se movendo

@export var hp: int = 30
@export var speed: float = 100.0
@export var damage: int = 10
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0 # Tempo entre ataques em segundos

var current_target = null # Dinâmico: Porta -> Rei
var attack_timer: Timer

@onready var animation_player = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	
	# Adiciona timer de ataque
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# O alvo inicial é a porta
	await get_tree().process_frame
	var gate = get_tree().get_first_node_in_group("gate")
	if gate:
		set_target(gate)

func _process(delta):
	# Não faz nada se estiver morto
	if current_state == State.DEATH: return
	
	match current_state:
		State.MOVE:
			if current_target and is_instance_valid(current_target):
				# Verifica se está no alcance de ataque do alvo
				if global_position.distance_to(current_target.global_position) <= attack_range:
					change_state(State.ATTACK)
				else:
					# Continua se movendo em direção ao alvo
					var direction = (current_target.global_position - global_position).normalized()
					position += direction * speed * delta
			else:
				# Se não tem alvo válido, procura o rei
				find_king_target()
		State.ATTACK:
			# A lógica de ataque é gerenciada pelo timer, a animação apenas roda
			# Se o alvo morrer, volta a andar
			if not current_target or not is_instance_valid(current_target):
				attack_timer.stop()
				find_king_target()

func find_king_target():
	var king = get_tree().get_first_node_in_group("king")
	if king:
		set_target(king)
	else:
		# Rei já morreu, jogo acabou
		change_state(State.IDLE)

func set_target(target):
	if target == null:
		current_target = null
		change_state(State.IDLE)
	else:
		current_target = target
		change_state(State.MOVE)
		attack_timer.stop() # Garante que o timer de ataque pare se ele começar a andar

func change_state(new_state):
	# Se o estado não mudou, não faz nada
	if current_state == new_state and animation_player.is_playing(): return
	
	current_state = new_state
	match new_state:
		State.IDLE: animation_player.play("idle")
		State.MOVE: animation_player.play("walk")
		State.ATTACK: 
			animation_player.play("attack")
			# Inicia o timer de ataque se for a primeira vez
			if attack_timer.is_stopped():
				attack_timer.start()
		State.DEATH: animation_player.play("death")

func _on_attack_timer_timeout():
	if current_state == State.ATTACK and current_target and is_instance_valid(current_target):
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage)
			print("Inimigo atacou! Causa ", damage, " de dano.")
		else:
			# Se o alvo não tem método take_damage, talvez seja a porta
			# Porta deve ter vida e gerenciar isso
			current_target.receive_damage(damage)

func take_damage(amount: int):
	if current_state == State.DEATH: return
	hp -= amount
	if hp <= 0:
		die()

func die():
	print("Inimigo morreu!")
	change_state(State.DEATH)
	
	# Para de atacar e se mover
	set_process(false) # Desativa o process para parar o movimento
	attack_timer.stop()
	
	# Espera a animação de morte acabar
	await animation_player.animation_finished
	queue_free() # Remove da cena
