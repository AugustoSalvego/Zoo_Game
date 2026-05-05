extends Control

@onready var btn_jogar = $BtnJogar

func _ready():
	estilizar_botao(btn_jogar)
	btn_jogar.pressed.connect(iniciar_jogo)

func iniciar_jogo():
	get_tree().change_scene_to_file("res://scenes/Jogo.tscn")

func estilizar_botao(botao):
	botao.add_theme_font_size_override("font_size", 60)
	botao.add_theme_color_override("font_color", Color.BLACK)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
	botao.add_theme_color_override("font_focus_color", Color.BLACK)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color.WHITE
	normal.border_color = Color.BLACK
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(25)
	normal.shadow_color = Color(0, 0, 0, 0.45)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(6, 6)

	var hover = normal.duplicate()
	hover.bg_color = Color(0.85, 0.95, 1.0)

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.75, 0.9, 1.0)

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", pressed)
