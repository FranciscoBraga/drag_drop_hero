extends Area2D

enum State {IDLE, MOVE, ATTACK, DEATH, VICTORY}
var current_state = State.IDLE

@export var max_health: int = 100
var current_health: int

# Status de Combate e Movimento
@export var speed: float = 40.0
@export var damage: int = 20
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var patrol_distance: float = 100.0 # Distância máxima que ele anda da posição inicial

var start_position: Vector2
var patrol_target: Vector2
var current_enemy_target = null

var current_attack_time: float = 0.0
var idle_time: float = 0.0

@onready var animation_player = $AnimatedSprite2D # Troque se o seu nó se chamar Sprite2D

func _ready():
	current_health = max_health
	add_to_group("king")
	
	# Memoriza o centro da torre para nunca cair
	start_position = global_position
	
	pick_new_patrol_point()
	change_state(State.IDLE)

func _process(delta):
	if current_state == State.DEATH: return

	# 1. Procura inimigos próximos o tempo todo
	find_closest_enemy()

	# 2. Se tem inimigo na área de alcance, vai para o ataque!
	if current_enemy_target and global_position.distance_to(current_enemy_target.global_position) <= attack_range:
		if current_state != State.ATTACK:
			change_state(State.ATTACK)
	
	# 3. A Máquina de Comportamentos
	match current_state:
		State.IDLE:
			idle_time -= delta
			if idle_time <= 0:
				pick_new_patrol_point()
				change_state(State.MOVE)
				
		State.MOVE:
			var direction = (patrol_target - global_position).normalized()
			
			# Vira o rosto para onde está andando
			if direction.x < 0:
				animation_player.flip_h = true
			elif direction.x > 0:
				animation_player.flip_h = false
			
			position += direction * speed * delta
			
			# Se chegou no ponto desejado, para e descansa
			if global_position.distance_to(patrol_target) < 5.0:
				change_state(State.IDLE)
				idle_time = randf_range(1.5, 3.5) # Fica parado entre 1.5 e 3.5 segundos
				
		State.ATTACK:
			# Se o inimigo morreu ou fugiu, volta a ficar de guarda
			if not current_enemy_target or not is_instance_valid(current_enemy_target) or global_position.distance_to(current_enemy_target.global_position) > attack_range:
				change_state(State.IDLE)
				idle_time = 1.0 # Descansa um pouco antes de andar
			else:
				# Vira o rosto para o inimigo na hora de bater
				animation_player.flip_h = current_enemy_target.global_position.x < global_position.x
				
				# A mesma lógica de ataque contínuo que fizemos para os Goblins
				current_attack_time += delta
				if current_attack_time >= attack_cooldown:
					current_attack_time = 0.0
					if current_enemy_target.has_method("take_damage"):
						current_enemy_target.take_damage(damage)

func pick_new_patrol_point():
	# Escolhe um ponto aleatório para esquerda ou direita, sem passar do limite
	var random_x = randf_range(-patrol_distance, patrol_distance)
	patrol_target = start_position + Vector2(random_x, 0)

func find_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_enemy = null
	var min_dist = attack_range # Só liga para inimigos que estão perto
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.current_state != enemy.State.DEATH:
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= min_dist:
				min_dist = dist
				closest_enemy = enemy
	
	current_enemy_target = closest_enemy

func change_state(new_state):
	# Evita tocar a mesma animação de novo
	if current_state == new_state: return
	
	current_state = new_state
	match new_state:
		State.IDLE: animation_player.play("idle")
		State.MOVE: animation_player.play("walk")
		State.ATTACK: 
			animation_player.play("attack")
			current_attack_time = attack_cooldown # O primeiro golpe é instantâneo!
		State.DEATH: animation_player.play("death")
		State.VICTORY:
			animation_player.play("victoria") # Coloque o nome exato da sua animação
			set_process(false)

func take_damage(amount: int):
	if current_state == State.DEATH: return
	current_health -= amount
	print("Rei tomou dano! Vida: ", current_health)
	if current_health <= 0:
		die()

func die():
	print("O Rei caiu! Vitória dos Monstros!")
	change_state(State.DEATH)
	get_tree().call_group("enemy", "celebrate")
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()

func celebrate():
	if current_state != State.DEATH:
		change_state(State.VICTORY)
