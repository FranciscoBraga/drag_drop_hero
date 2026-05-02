extends Area2D

# Estados possíveis para animação
enum State {IDLE, MOVE, ATTACK, DEATH,TELEPORTING,VICTORY}
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
var gate = null

@onready var animation_player = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	print("castle_level:",castle_level)
	
	# Adiciona timer de ataque
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# O alvo inicial é a porta
	await get_tree().process_frame
	gate = get_tree().get_first_node_in_group("gate")
	if gate:
		set_target(gate)

func _process(delta):
	# Não faz nada se estiver morto
	if current_state == State.DEATH: return
	if current_state == State.DEATH or current_state == State.TELEPORTING: 
		return
	
	match current_state:
		State.MOVE:
			if current_target and is_instance_valid(current_target):
				
				# 1. Calcula a direção SEMPRE (para o flip e para andar)
				var direction = (current_target.global_position - global_position).normalized()
				
				# 2. Vira o sprite para o lado certo IMEDIATAMENTE
				if direction.x < 0:
					animation_player.flip_h = true # Esquerda
				elif direction.x > 0:
					animation_player.flip_h = false # Direita

				# 3. Lógica de movimentação
				if current_target.is_in_group("gate") and current_target.get("is_broken") == true:
					if global_position.distance_to(current_target.global_position) > 10.0:
						position += direction * speed * delta
					else:
						teleport_to_next_level()
						
				elif global_position.distance_to(current_target.global_position) <= attack_range:
					change_state(State.ATTACK)
					
				else:
					position += direction * speed * delta
			else:
				find_king_target()
				
		State.ATTACK:
			# SE O ALVO SUMIR (ex: herói morreu)
			if not current_target or not is_instance_valid(current_target):
				attack_timer.stop()
				find_king_target() # Procura o rei e volta a andar
				
			# SE A PORTA QUEBRAR ENQUANTO ELE ESTÁ BATENDO NELA
			elif current_target.is_in_group("gate") and current_target.get("is_broken") == true:
				attack_timer.stop()
				# Como ele já estava batendo, sabemos que ele está encostado no portal!
				# Então ativamos o teletransporte IMEDIATAMENTE
				teleport_to_next_level()
				
func find_king_target():
	var king = get_tree().get_first_node_in_group("king")
	if king:
		set_target(king)
		print("king")
	else:
		# Rei já morreu, jogo acabou
		change_state(State.IDLE)
		print("IDLE")

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
	print("current_state:",current_state)
	match new_state:
		State.IDLE: animation_player.play("idle")
		State.MOVE: animation_player.play("walk")
		State.ATTACK: 
			animation_player.play("attack")
			# Inicia o timer de ataque se for a primeira vez
			if attack_timer.is_stopped():
				attack_timer.start()
		State.DEATH: animation_player.play("death")
		State.TELEPORTING:
			# Para tudo que estiver fazendo
			animation_player.stop()
			attack_timer.stop()
		State.VICTORY: # <--- NOVO ESTADO AQUI
			animation_player.play("victoria")
			attack_timer.stop()
			set_process(false) # Faz o inimigo parar de andar e pensar
		
# --- ATUALIZE SUA FUNÇÃO _on_area_entered ---
func _on_area_entered(area: Area2D):
	print("_on_area_entered")
	# Lógica de dano original para rei e herói...
	if area.is_in_group("king") or area.is_in_group("hero"):
		if area.has_method("take_damage"):
			print("inimigo sobre ataque")
			area.take_damage(damage)
			# queue_free() # ou lógica de combate
			# NOVA LÓGICA: Se tocou na porta
	if area.is_in_group("gate"):
		print("gate")
			# Verifica se a porta tem a variável is_broken e se ela é verdadeira
		if area.get("is_broken") == true:
			print("is_broken")
			teleport_to_next_level()

# --- NOVA FUNÇÃO DE TELETRANSPORTE ---
func teleport_to_next_level():
	print("teleport_to_next_level")
	# Previne que a função rode mais de uma vez se ele esbarrar duas vezes na porta
	if current_state == State.TELEPORTING: return 
	
	# Muda o estado e fica invisível
	change_state(State.TELEPORTING)
	visible = false 
	
	
	# O CÓDIGO PAUSA AQUI POR 5 SEGUNDOS APENAS PARA ESTE INIMIGO
	await get_tree().create_timer(5.0).timeout
	
	# Checagem de segurança: Se a fase reiniciou ou ele foi destruído enquanto esperava
	if not is_inside_tree() or current_state == State.DEATH: return
	
	# --- Lógica de achar o marcador ---
	castle_level += 1
	print("castle_level:",castle_level)
	var castle_node = get_tree().current_scene.get_node_or_null("Castle")
	if castle_node:
		var marker_right_name = "level_right_" + str(castle_level)
		var marker_left_name = "level_left_" + str(castle_level)
		
		var marker_right = castle_node.get_node_or_null(marker_right_name)
		var marker_left = castle_node.get_node_or_null(marker_left_name)
		
		var possible_markers = []
		if marker_right: possible_markers.append(marker_right)
		if marker_left: possible_markers.append(marker_left)
		
		if possible_markers.size() > 0:
			var chosen_marker = possible_markers.pick_random()
			global_position = chosen_marker.global_position
		else:
			print("Erro: Nenhum marcador encontrado para o level ", castle_level)
			
	# --- A Mágica de Volta ---
	visible = true # Fica visível novamente
	
	# Manda ele procurar o Rei, o que automaticamente muda o estado dele de volta para MOVE
	find_king_target()
			
				
func _on_attack_timer_timeout():
	if current_state == State.ATTACK and current_target and is_instance_valid(current_target):
		
		# Tenta causar dano no Rei ou Herói
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage)
			print("Inimigo atacou o alvo!")
			
		# Se não for Rei/Herói, tenta causar dano na Porta!
		elif current_target.has_method("receive_damage"):
			current_target.receive_damage(damage)
			print("Inimigo atacou o PORTÃO!")

func take_damage(amount: int):
	if current_state == State.DEATH: return
	hp -= amount
	if hp <= 0:
		die()

func die():
	print("Olá morri")
	change_state(State.DEATH)
	
	# Para de atacar e se mover
	set_process(false) # Desativa o process para parar o movimento
	attack_timer.stop()
	
	# Espera a animação de morte acabar
	await animation_player.animation_finished
	queue_free() # Remove da cena
# 3. Crie esta função no final do script
func celebrate():
	if current_state != State.DEATH: # Só comemora se estiver vivo!
		change_state(State.VICTORY)
