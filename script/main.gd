extends Node2D

# Variáveis no topo do Main.gd
var is_dragging: bool = false
var dragged_hero_packed: PackedScene = null
var current_drag_ghost: Node2D = null
@export var level_waves: Array[Wave]
var current_wave_index: int = 0
var spawned_in_current_wave: int = 0
var spawn_timer: Timer

@export var linha_do_castelo_y: float = 400.0 # Ajuste este valor no Inspector depois!
# Adicione esta variável no topo do Main.gd
var todas_ondas_finalizadas: bool = false
var jogo_acabou: bool = false # Evita que a vitória rode várias vezes

func _ready():
	var gate = get_tree().get_first_node_in_group("gate")
	if gate:
		gate.gate_broken.connect(_on_gate_broken)
	# Cria um timer simples via código para spawnar inimigos
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0 # Spawna um inimigo a cada 2 segundos
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)
	# Prepara o timer de spawn dinâmico
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)
	
	# Inicia a primeira onda
	start_next_wave()
	
func _process(delta):
	if todas_ondas_finalizadas and not jogo_acabou:
		# Conta quantos inimigos existem no mapa
		var inimigos_vivos = get_tree().get_nodes_in_group("enemy").size()
		
		if inimigos_vivos == 0:
			declarar_vitoria()
	
func start_next_wave():
	if current_wave_index < level_waves.size():
		spawned_in_current_wave = 0
		var current_wave = level_waves[current_wave_index]
		
		print("Iniciando Onda ", current_wave_index + 1)
		
		# Ajusta a velocidade do timer com base na configuração da onda
		spawn_timer.wait_time = current_wave.spawn_interval
		spawn_timer.start()
	else:
		print("A Fase acabou! Todos os inimigos foram enviados.")
		spawn_timer.stop()
		# Aqui no futuro você pode chamar a tela de "Vitória"

func _spawn_enemy():
	# TRAVA DE SEGURANÇA: Se o índice for maior ou igual ao total de ondas, para o spawn e sai da função!
	if current_wave_index >= level_waves.size():
		spawn_timer.stop()
		todas_ondas_finalizadas = true # Avisa que não vem mais ninguém!
		return
	var current_wave = level_waves[current_wave_index]
	
	# IMPORTANTE: Puxa a cena de dentro da ONDA, e não do Main!
	if current_wave.enemy_scene:
		var enemy = current_wave.enemy_scene.instantiate()
		
		# Sorteia esquerda ou direita
		if randi() % 2 == 0:
			enemy.global_position = $SpawnLeft.global_position
		else:
			enemy.global_position = $SpawnRight.global_position
			
		add_child(enemy)
		spawned_in_current_wave += 1
		
		# Verifica se já spawnou todos os inimigos desta onda
		if spawned_in_current_wave >= current_wave.enemy_count:
			spawn_timer.stop()
			current_wave_index += 1
			
			await get_tree().create_timer(3.0).timeout
			start_next_wave()
	else:
		print("ERRO: A onda ", current_wave_index, " está sem uma cena de inimigo definida no Inspector!")
func start_dragging_hero(hero_packed):
	print("3. O MAIN RECEBEU O HERÓI!") # Rastreio 3
	if is_dragging: return 
	is_dragging = true
	dragged_hero_packed = hero_packed
	current_drag_ghost = dragged_hero_packed.instantiate()
	add_child(current_drag_ghost) 
	current_drag_ghost.modulate.a = 0.5 
	current_drag_ghost.global_position = get_global_mouse_position()
	
func _input(event):
	if is_dragging:
		if event is InputEventMouseMotion:
			if current_drag_ghost:
				current_drag_ghost.global_position = get_global_mouse_position()
		
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			stop_dragging_hero()

func stop_dragging_hero():
	is_dragging = false
	
	var new_hero = dragged_hero_packed.instantiate()
	add_child(new_hero) 
	new_hero.global_position = get_global_mouse_position()
	
	# --- LÓGICA DE PROFUNDIDADE (Z-INDEX) ---
	# Se a posição Y do herói for menor (mais alto na tela) que a linha do castelo
	if new_hero.global_position.y < linha_do_castelo_y:
		new_hero.z_index = -1 # Fica atrás da muralha da frente (igual o Rei)
	else:
		new_hero.z_index = 5  # Fica na frente do chão e dos inimigos normais
	
	if current_drag_ghost:
		current_drag_ghost.queue_free()
	current_drag_ghost = null
	dragged_hero_packed = null
func _on_gate_broken():
	print("O Main foi avisado que a porta quebrou!")
	
func declarar_vitoria():
	jogo_acabou = true
	print("Fase Concluída! Vitória do Jogador!")
	
	# Manda o Rei e todos os Heróis vivos comemorarem!
	get_tree().call_group("king", "celebrate")
	get_tree().call_group("hero", "celebrate")
	
	# Aqui você pode chamar um painel de "Próxima Fase" ou voltar pro menu
