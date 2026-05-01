extends Button

@export var hero_scene: PackedScene 
@export var hero_icon: Texture2D 

@onready var icon_rect = $Icon

func _ready():
	button_down.connect(_on_button_down)
	if hero_icon and icon_rect:
		icon_rect.texture = hero_icon

func _on_button_down():
	print("1. CLIQUEI NO BOTÃO!") # Rastreio 1
	
	var main_node = get_tree().current_scene
	if main_node.has_method("start_dragging_hero"):
		print("2. ACHEI O MAIN, ENVIANDO HERÓI...") # Rastreio 2
		main_node.start_dragging_hero(hero_scene)
	else:
		print("ERRO: O Main não tem a função start_dragging_hero!")
