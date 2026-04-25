extends Control # Pode ser TextureRect, Panel, ou ColorRect

@export var hero_scene: PackedScene # Arraste a cena Hero.tscn para cá no Inspector
var is_dragging: bool = false
var dragged_hero: Node2D = null

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Jogador clicou na caixa: Instancia o herói e começa o drag
			is_dragging = true
			dragged_hero = hero_scene.instantiate()
			
			# Adiciona o herói à cena principal (fora da UI)
			get_tree().current_scene.add_child(dragged_hero)
			
			# Deixa o herói meio transparente enquanto está sendo arrastado
			dragged_hero.modulate.a = 0.5 
			dragged_hero.global_position = get_global_mouse_position()
			
		elif not event.pressed and is_dragging:
			# Jogador soltou o botão do mouse: Posiciona o herói
			is_dragging = false
			if dragged_hero:
				dragged_hero.modulate.a = 1.0 # Remove a transparência
				dragged_hero = null

func _process(_delta):
	# Se estiver arrastando, o herói fantasma segue o mouse
	if is_dragging and dragged_hero:
		dragged_hero.global_position = get_global_mouse_position()
