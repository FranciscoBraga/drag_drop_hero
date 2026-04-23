extends Node2D

@export var enemy_scene: PackedScene # Arraste a cena Enemy.tscn para cá

func _ready():
	# Cria um timer simples via código para spawnar inimigos
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0 # Spawna um inimigo a cada 2 segundos
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)

func _spawn_enemy():
	var enemy = enemy_scene.instantiate()
	
	# Sorteia se o inimigo vem da esquerda ou da direita
	if randi() % 2 == 0:
		enemy.global_position = $SpawnLeft.global_position
		enemy.direction = Vector2.RIGHT # Vai para a direita (em direção ao castelo)
	else:
		enemy.global_position = $SpawnRight.global_position
		enemy.direction = Vector2.LEFT # Vai para a esquerda
		
	add_child(enemy)
