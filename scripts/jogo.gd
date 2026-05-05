extends Control

@onready var layout = $Layout
@onready var fundo_jogo = $Layout/FundoJogo
@onready var caixa_palavra = $Layout/CaixaPalavra
@onready var lbl_palavra = $Layout/CaixaPalavra/LblPalavra
@onready var caixa_animal = $Layout/CaixaAnimal
@onready var img_animal = $Layout/CaixaAnimal/ImgAnimal
@onready var btn1 = $Layout/Btn1
@onready var btn2 = $Layout/Btn2
@onready var btn3 = $Layout/Btn3
@onready var btn_reiniciar = $Layout/BtnReiniciar

var fase_atual = 0
var resposta_correta = ""

var fases = [
	{"animal": "CACHORRO", "incompleto": "__CHORRO", "silaba": "CA", "opcoes": ["CA", "BA", "PA"], "imagem": "res://img/cachorro.png"},
	{"animal": "GATO", "incompleto": "__TO", "silaba": "GA", "opcoes": ["PA", "GA", "CA"], "imagem": "res://img/gato.png"},
	{"animal": "MACACO", "incompleto": "__CACO", "silaba": "MA", "opcoes": ["MA", "PA", "TA"], "imagem": "res://img/macaco.png"},
	{"animal": "BALEIA", "incompleto": "__LEIA", "silaba": "BA", "opcoes": ["BA", "GA", "LA"], "imagem": "res://img/baleia.png"},
	{"animal": "CAVALO", "incompleto": "__VALO", "silaba": "CA", "opcoes": ["CA", "SA", "RA"], "imagem": "res://img/cavalo.png"},
	{"animal": "GALINHA", "incompleto": "__LINHA", "silaba": "GA", "opcoes": ["MA", "GA", "TA"], "imagem": "res://img/galinha.png"},
	{"animal": "TARTARUGA", "incompleto": "__RTARUGA", "silaba": "TA", "opcoes": ["TA", "CA", "FA"], "imagem": "res://img/tartaruga.png"}
]

func _ready():
	configurar_layout()
	estilizar_interface()

	btn1.pressed.connect(func(): verificar_resposta(btn1.text))
	btn2.pressed.connect(func(): verificar_resposta(btn2.text))
	btn3.pressed.connect(func(): verificar_resposta(btn3.text))
	btn_reiniciar.pressed.connect(reiniciar_jogo)

	btn_reiniciar.hide()
	carregar_fase()

func configurar_layout():
	var tela = get_viewport_rect().size

	layout.position = Vector2.ZERO
	layout.size = tela

	fundo_jogo.position = Vector2.ZERO
	fundo_jogo.size = tela
	fundo_jogo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	caixa_animal.size = Vector2(450, 450)
	caixa_animal.position = Vector2((tela.x - caixa_animal.size.x) / 2, 90)

	img_animal.position = Vector2.ZERO
	img_animal.size = caixa_animal.size
	img_animal.custom_minimum_size = Vector2.ZERO
	img_animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	caixa_palavra.size = Vector2(560, 150)
	caixa_palavra.position = Vector2((tela.x - caixa_palavra.size.x) / 2, 600)
	lbl_palavra.position = Vector2.ZERO
	lbl_palavra.size = caixa_palavra.size
	lbl_palavra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_palavra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var largura_botao = 230
	var altura_botao = 120
	var y_botoes = 820

	btn1.size = Vector2(largura_botao, altura_botao)
	btn2.size = Vector2(largura_botao, altura_botao)
	btn3.size = Vector2(largura_botao, altura_botao)

	btn1.position = Vector2(430, y_botoes)
	btn2.position = Vector2(845, y_botoes)
	btn3.position = Vector2(1260, y_botoes)

	btn_reiniciar.size = Vector2(430, 110)
	btn_reiniciar.position = Vector2((tela.x - btn_reiniciar.size.x) / 2, 800)

func estilizar_interface():
	lbl_palavra.add_theme_font_size_override("font_size", 64)
	lbl_palavra.add_theme_color_override("font_color", Color.BLACK)

	estilizar_painel(caixa_palavra, Color.WHITE)

	estilizar_painel(caixa_animal, Color(0.45, 0.6, 0.45))
	estilizar_botao(btn_reiniciar)
	btn_reiniciar.add_theme_font_size_override("font_size", 38)
	
	estilizar_botao(btn1)
	estilizar_botao(btn2)
	estilizar_botao(btn3)

func estilizar_painel(painel, cor):
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(25)
	estilo.shadow_color = Color(0, 0, 0, 0.45)
	estilo.shadow_size = 10
	estilo.shadow_offset = Vector2(8, 8)
	painel.add_theme_stylebox_override("panel", estilo)

func estilizar_botao(botao):
	botao.add_theme_font_size_override("font_size", 52)
	botao.add_theme_color_override("font_color", Color.BLACK)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
	botao.add_theme_color_override("font_focus_color", Color.BLACK)
	botao.add_theme_color_override("font_disabled_color", Color.BLACK)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color.WHITE
	normal.border_color = Color.BLACK
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(22)
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

func carregar_fase():
	if fase_atual >= fases.size():
		lbl_palavra.text = "PARABÉNS!"
		caixa_animal.hide()
		btn1.hide()
		btn2.hide()
		btn3.hide()
		btn_reiniciar.show()
		return

	var fase = fases[fase_atual]
	resposta_correta = fase["silaba"]

	caixa_animal.show()  # 👈 IMPORTANTE (volta o animal)
	btn_reiniciar.hide() # 👈 esconde botão de reiniciar

	lbl_palavra.text = fase["incompleto"]
	lbl_palavra.add_theme_color_override("font_color", Color.BLACK)

	img_animal.texture = load(fase["imagem"])

	var opcoes = fase["opcoes"].duplicate()
	opcoes.shuffle()

	btn1.text = opcoes[0]
	btn2.text = opcoes[1]
	btn3.text = opcoes[2]

	btn1.disabled = false
	btn2.disabled = false
	btn3.disabled = false

	btn1.show()
	btn2.show()
	btn3.show()

func verificar_resposta(resposta):
	var fase = fases[fase_atual]

	btn1.disabled = true
	btn2.disabled = true
	btn3.disabled = true

	if resposta == resposta_correta:
		lbl_palavra.text = fase["animal"]
		lbl_palavra.add_theme_color_override("font_color", Color.BLACK)
		estilizar_painel(caixa_palavra, Color(0.55, 1.0, 0.25))
		await get_tree().create_timer(1.2).timeout
		estilizar_painel(caixa_palavra, Color.WHITE)
		fase_atual += 1
		carregar_fase()
	else:
		lbl_palavra.text = resposta + fase["animal"].substr(2)
		lbl_palavra.add_theme_color_override("font_color", Color.BLACK)
		estilizar_painel(caixa_palavra, Color(1.0, 0.35, 0.35))
		await get_tree().create_timer(1.2).timeout
		estilizar_painel(caixa_palavra, Color.WHITE)
		carregar_fase()

func reiniciar_jogo():
	fase_atual = 0
	btn_reiniciar.hide()
	btn1.show()
	btn2.show()
	btn3.show()
	carregar_fase()
	
