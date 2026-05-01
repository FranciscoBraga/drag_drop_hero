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
# Adicione esta variável no topo junto com as outras
var castle_level: int = 0

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
				
				# REGRA 1: Se o alvo for a porta e ela JÁ ESTIVER QUEBRADA
				if current_target.is_in_group("gate") and current_target.get("is_broken") == true:
					# Ignora a distância de ataque e anda direto para dentro do portal!
					var direction = (current_target.global_position - global_position).normalized()
					position += direction * speed * delta
				
				# REGRA 2: Se o alvo está vivo e chegou na distância de bater
				elif global_position.distance_to(current_target.global_position) <= attack_range:
					change_state(State.ATTACK)
				
				# REGRA 3: Ainda não chegou perto, continua andando
				else:
					var direction = (current_target.global_position - global_position).normalized()
					position += direction * speed * delta
			else:
				# Se não tem alvo válido, procura o rei
				find_king_target()
				
		State.ATTACK:
			# SE O ALVO SUMIR ou SE A PORTA QUEBRAR ENQUANTO ELE BATE
			if not current_target or not is_instance_valid(current_target) or (current_target.is_in_group("gate") and current_target.get("is_broken") == true):
				attack_timer.stop()
				change_state(State.MOVE) # Volta a andar para entrar no portal

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
		
# --- ATUALIZE SUA FUNÇÃO _on_area_entered ---
func _on_area_entered(area: Area2D):
	print("_on_area_entered")
	# Lógica de dano original para rei e herói...
	if area.is_in_group("king") or area.is_in_group("hero"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
			# queue_free() # ou lógica de combate
			# NOVA LÓGICA: Se tocou na porta
	if area.is_in_group("gate"):
		print("gate")
			# Verifica se a porta tem a variável is_broken e se ela é verdadeira
		if area.get("is_broken") == true:
			teleport_to_next_level()

# --- NOVA FUNÇÃO DE TELETRANSPORTE ---
func teleport_to_next_level():
	castle_level += 1
	print("Inimigo entrou no portal! Subindo para o andar: ", castle_level)
	
	# Busca o nó 'Castle' na cena principal
	var castle_node = get_tree().current_scene.get_node_or_null("Castle")
	if not castle_node:
		print("Erro: Nó 'Castle' não encontrado para buscar os marcadores.")
		return
		
	# Constrói o nome dos marcadores dinamicamente baseado no level atual
	var marker_right_name = "level_right_" + str(castle_level)
	var marker_left_name = "level_left_" + str(castle_level)
	
	# Busca os nós dentro do castelo
	var marker_right = castle_node.get_node_or_null(marker_right_name)
	var marker_left = castle_node.get_node_or_null(marker_left_name)
	
	var possible_markers = []
	if marker_right: possible_markers.append(marker_right)
	if marker_left: possible_markers.append(marker_left)
	
	# Se encontrou pelo menos um marcador para esse andar
	if possible_markers.size() > 0:
		# Escolhe aleatoriamente entre esquerda (0) e direita (1)
		var chosen_marker = possible_markers.pick_random()
		
		# Teletransporta o inimigo
		global_position = chosen_marker.global_position
		
		# AGORA SIM, após subir de andar, ele define o Rei como alvo
		find_king_target()
	else:
		print("Erro: Nenhum marcador encontrado para o level ", castle_level)
		# Plano B: Vai pro rei mesmo sem marcador
		find_king_target()				
				
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
