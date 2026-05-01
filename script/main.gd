extends Node2D

@export var enemy_scene: PackedScene # Arraste a cena Enemy.tscn para cá
# Variáveis no topo do Main.gd
var is_dragging: bool = false
var dragged_hero_packed: PackedScene = null
var current_drag_ghost: Node2D = null

func _ready():
	# Cria um timer simples via código para spawnar inimigos
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0 # Spawna um inimigo a cada 2 segundos
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)

func _spawn_enemy():
	var enemy = enemy_scene.instantiate()
	
	# Sorteia se o inimigo nasce no marcador da esquerda ou da direita
	if randi() % 2 == 0:
		enemy.global_position = $SpawnLeft.global_position
	else:
		enemy.global_position = $SpawnRight.global_position
		# Adiciona na cena. Não precisamos mais definir enemy.direction
		# O próprio Enemy.gd vai procurar a porta no seu _ready() e ir até ela.
	add_child(enemy)
	
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
	print("4. SOLTEI O HERÓI NO MAPA!") # Rastreio 4
	is_dragging = false
	
	var new_hero = dragged_hero_packed.instantiate()
	add_child(new_hero) 
	new_hero.global_position = get_global_mouse_position()
	
	if current_drag_ghost:
		current_drag_ghost.queue_free()
	current_drag_ghost = null
	dragged_hero_packed = null
