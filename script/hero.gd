extends Area2D

enum State {IDLE, MOVE, ATTACK, DEATH, VICTORY}
var current_state = State.IDLE # Herói nasce parado defendendo
# Adicione esta variável no topo do Main.gd

@export var max_health: int = 50
var current_health: int
@export var damage: int = 15
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.2
@export var is_flying: bool = false # Se marcar como TRUE no Inspector, ele não cai
var is_grounded: bool = false
var gravity_speed: float = 300.0

var is_dead: bool = false # Variável para os inimigos saberem que ele morreu

var attack_timer: Timer
var current_target = null # Dinâmico: Inimigo mais próximo

@onready var animation_player = $AnimatedSprite2D

func _ready():
	current_health = max_health
	add_to_group("hero")
	
	# Detecta quando bater no chão (seja Area2D ou StaticBody2D)
	area_entered.connect(_on_floor_detected)
	body_entered.connect(_on_floor_detected)
	
	# Adiciona timer de ataque
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	change_state(State.IDLE)

func _process(delta):
	# APLICA GRAVIDADE SE NÃO ESTIVER VOANDO E NÃO ESTIVER NO CHÃO
	if not is_flying and not is_grounded and current_state != State.DEATH:
		position.y += gravity_speed * delta
	if current_state == State.DEATH: return
	
	# Se não tem alvo, procura o inimigo mais próximo
	if not current_target or not is_instance_valid(current_target):
		find_closest_enemy()
		
	match current_state:
		State.IDLE:
			# Se encontrou inimigo, e está no alcance, ataca
			if current_target and global_position.distance_to(current_target.global_position) <= attack_range:
				change_state(State.ATTACK)
		State.ATTACK:
			# Lógica gerenciada pelo timer
			if not current_target or not is_instance_valid(current_target):
				attack_timer.stop()
				change_state(State.IDLE)
		# Heróis no protótipo não andam, apenas lutam e morrem
		State.MOVE: pass 
		State.VICTORY:
			animation_player.play("victoria") # Coloque o nome exato da sua animação
			if attack_timer: attack_timer.stop()
			set_process(false)

func find_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		current_target = null
		return
		
	# Encontra o inimigo mais próximo usando a distância euclidiana simples
	var closest_enemy = null
	var min_dist = INF
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_enemy = enemy
	
	current_target = closest_enemy

func change_state(new_state):
	if current_state == new_state and animation_player.is_playing(): return
	
	current_state = new_state
	match new_state:
		State.IDLE: animation_player.play("idle")
		State.MOVE: animation_player.play("walk")
		State.ATTACK: 
			animation_player.play("attack")
			if attack_timer.is_stopped():
				attack_timer.start()
		State.DEATH: animation_player.play("death")
		State.VICTORY:
			animation_player.play("victoria") # Coloque o nome exato da sua animação
			if attack_timer: attack_timer.stop()
			set_process(false)

func _on_attack_timer_timeout():
	if current_state == State.ATTACK and current_target and is_instance_valid(current_target):
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage)
			print("Herói atacou! Causa ", damage, " de dano.")

func take_damage(amount: int):
	if current_state == State.DEATH: return
	current_health -= amount
	
	# EFEITO DE DANO: Fica vermelho e volta ao normal em 0.3 segundos
	modulate = Color(1, 0, 0) # Vermelho
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3) # Volta ao branco/normal
	
	if current_health <= 0:
		die()
		
func die():
	is_dead = true # Avisa que morreu
	change_state(State.DEATH)
	if attack_timer: attack_timer.stop()
	
	# DESATIVA A COLISÃO (Ponto 3: Inimigos não grudam mais nele!)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# EFEITO DE MORTE: Fica vermelho escuro e vai ficando invisível (Fade out)
	modulate = Color(0.8, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0) # Fica invisível em 1 segundo
	
	await animation_player.animation_finished
	queue_free()
	
func celebrate():
	if current_state != State.DEATH:
		change_state(State.VICTORY)

func _on_floor_detected(body_or_area):
	if body_or_area.is_in_group("chao"):
		is_grounded = true
