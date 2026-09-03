extends Control

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const GameMetrics = preload("res://scripts/game_metrics.gd")

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

var audio
var metrics
var fase_atual := 0
var resposta_correta := ""
var respondendo := false

var progress_label: Label
var instruction_label: Label
var btn_voltar: Button
var btn_ajuda: Button
var btn_repetir: Button
var btn_volume: Button
var volume_panel: Panel
var volume_slider: HSlider
var btn_menu_final: Button

var fases = [
	{"animal": "CACHORRO", "audio": "cachorro", "incompleto": "__CHORRO", "silaba": "CA", "opcoes": ["CA", "BA", "PA"], "imagem": "res://img/cachorro.png"},
	{"animal": "GATO", "audio": "gato", "incompleto": "__TO", "silaba": "GA", "opcoes": ["PA", "GA", "CA"], "imagem": "res://img/gato.png"},
	{"animal": "MACACO", "audio": "macaco", "incompleto": "__CACO", "silaba": "MA", "opcoes": ["MA", "PA", "TA"], "imagem": "res://img/macaco.png"},
	{"animal": "BALEIA", "audio": "baleia", "incompleto": "__LEIA", "silaba": "BA", "opcoes": ["BA", "GA", "LA"], "imagem": "res://img/baleia.png"},
	{"animal": "CAVALO", "audio": "cavalo", "incompleto": "__VALO", "silaba": "CA", "opcoes": ["CA", "SA", "RA"], "imagem": "res://img/cavalo.png"},
	{"animal": "GALINHA", "audio": "galinha", "incompleto": "__LINHA", "silaba": "GA", "opcoes": ["MA", "GA", "TA"], "imagem": "res://img/galinha.png"},
	{"animal": "TARTARUGA", "audio": "tartaruga", "incompleto": "__RTARUGA", "silaba": "TA", "opcoes": ["TA", "CA", "FA"], "imagem": "res://img/tartaruga.png"}
]

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	audio.play_music("game")

	metrics = GameMetrics.new()
	add_child(metrics)
	metrics.iniciar_sessao()

	configurar_layout()
	estilizar_interface()
	criar_controles_acessibilidade()

	btn1.pressed.connect(func(): verificar_resposta(btn1.text))
	btn2.pressed.connect(func(): verificar_resposta(btn2.text))
	btn3.pressed.connect(func(): verificar_resposta(btn3.text))
	btn_reiniciar.pressed.connect(reiniciar_jogo)

	btn1.mouse_entered.connect(func(): falar_silaba(btn1.text))
	btn2.mouse_entered.connect(func(): falar_silaba(btn2.text))
	btn3.mouse_entered.connect(func(): falar_silaba(btn3.text))

	btn_reiniciar.hide()
	carregar_fase()

func configurar_layout() -> void:
	var tela := get_viewport_rect().size
	layout.position = Vector2.ZERO
	layout.size = tela
	fundo_jogo.position = Vector2.ZERO
	fundo_jogo.size = tela
	fundo_jogo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	caixa_animal.size = Vector2(450, 450)
	caixa_animal.position = Vector2((tela.x - caixa_animal.size.x) / 2.0, 110)
	img_animal.position = Vector2.ZERO
	img_animal.size = caixa_animal.size
	img_animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	caixa_palavra.size = Vector2(560, 150)
	caixa_palavra.position = Vector2((tela.x - caixa_palavra.size.x) / 2.0, 600)
	lbl_palavra.position = Vector2.ZERO
	lbl_palavra.size = caixa_palavra.size
	lbl_palavra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_palavra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var largura_botao := 230
	var altura_botao := 120
	var y_botoes := 825
	btn1.size = Vector2(largura_botao, altura_botao)
	btn2.size = Vector2(largura_botao, altura_botao)
	btn3.size = Vector2(largura_botao, altura_botao)
	btn1.position = Vector2(430, y_botoes)
	btn2.position = Vector2(845, y_botoes)
	btn3.position = Vector2(1260, y_botoes)

	btn_reiniciar.size = Vector2(430, 110)
	btn_reiniciar.position = Vector2(510, 820)
	btn_reiniciar.text = "JOGAR DE NOVO"

func estilizar_interface() -> void:
	lbl_palavra.add_theme_font_size_override("font_size", 64)
	lbl_palavra.add_theme_color_override("font_color", Color.BLACK)
	estilizar_painel(caixa_palavra, Color.WHITE)
	estilizar_painel(caixa_animal, Color(0.78, 0.92, 0.78))
	estilizar_botao(btn_reiniciar)
	btn_reiniciar.add_theme_font_size_override("font_size", 34)
	estilizar_botao(btn1)
	estilizar_botao(btn2)
	estilizar_botao(btn3)

func criar_controles_acessibilidade() -> void:
	var tela := get_viewport_rect().size

	progress_label = Label.new()
	progress_label.size = Vector2(520, 64)
	progress_label.position = Vector2((tela.x - 520) / 2.0, 24)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 30)
	progress_label.add_theme_color_override("font_color", Color.BLACK)
	layout.add_child(progress_label)

	instruction_label = Label.new()
	instruction_label.size = Vector2(850, 56)
	instruction_label.position = Vector2((tela.x - 850) / 2.0, 755)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 28)
	instruction_label.add_theme_color_override("font_color", Color.BLACK)
	layout.add_child(instruction_label)

	btn_voltar = criar_botao_topo("↩", Vector2(24, 24), "ui_back")
	btn_voltar.pressed.connect(voltar_menu)

	btn_ajuda = criar_botao_topo("?", Vector2(124, 24), "ui_help")
	btn_ajuda.pressed.connect(abrir_tutorial)

	btn_repetir = criar_botao_topo("🔊", Vector2(224, 24), "ui_repeat")
	btn_repetir.pressed.connect(repetir_instrucao)

	btn_volume = criar_botao_topo("SOM", Vector2(tela.x - 138, 24), "ui_volume")
	btn_volume.size = Vector2(114, 72)
	btn_volume.pressed.connect(toggle_volume_panel)

	volume_panel = Panel.new()
	volume_panel.size = Vector2(300, 90)
	volume_panel.position = Vector2(tela.x - 330, 108)
	volume_panel.visible = false
	estilizar_painel(volume_panel, Color(1, 1, 1, 0.95))
	layout.add_child(volume_panel)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = audio.load_saved_volume()
	volume_slider.size = Vector2(245, 40)
	volume_slider.position = Vector2(28, 24)
	volume_slider.value_changed.connect(func(value: float): audio.save_master_volume(value))
	volume_panel.add_child(volume_slider)

	btn_menu_final = Button.new()
	btn_menu_final.text = "VOLTAR AO MENU"
	btn_menu_final.size = Vector2(430, 110)
	btn_menu_final.position = Vector2(980, 820)
	btn_menu_final.visible = false
	estilizar_botao(btn_menu_final)
	btn_menu_final.add_theme_font_size_override("font_size", 32)
	btn_menu_final.pressed.connect(voltar_menu)
	layout.add_child(btn_menu_final)

func criar_botao_topo(texto: String, posicao: Vector2, voice_key: String) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.size = Vector2(90, 72)
	botao.position = posicao
	estilizar_botao(botao)
	botao.add_theme_font_size_override("font_size", 30)
	botao.mouse_entered.connect(func(): audio.play_hover_voice(voice_key))
	layout.add_child(botao)
	return botao

func carregar_fase() -> void:
	respondendo = false
	if fase_atual >= fases.size():
		finalizar_jogo()
		return

	var fase = fases[fase_atual]
	resposta_correta = fase["silaba"]
	caixa_animal.show()
	btn_reiniciar.hide()
	btn_menu_final.hide()
	lbl_palavra.text = fase["incompleto"]
	lbl_palavra.add_theme_color_override("font_color", Color.BLACK)
	img_animal.texture = load(fase["imagem"])
	instruction_label.text = "Escolha a sílaba que completa o nome."
	atualizar_progresso()

	var opcoes = fase["opcoes"].duplicate()
	opcoes.shuffle()
	btn1.text = opcoes[0]
	btn2.text = opcoes[1]
	btn3.text = opcoes[2]

	for botao in [btn1, btn2, btn3]:
		botao.disabled = false
		botao.show()

	call_deferred("anunciar_fase")

func anunciar_fase() -> void:
	if fase_atual >= fases.size():
		return
	var fase = fases[fase_atual]
	await audio.speak_and_wait("animal_" + fase["audio"], 0.4)
	await audio.speak_and_wait("instruction_choose_syllable", 0.6)

func repetir_instrucao() -> void:
	if fase_atual >= fases.size():
		audio.play_voice("final_congratulations")
		return
	anunciar_fase()

func falar_silaba(silaba: String) -> void:
	if respondendo:
		return
	audio.play_hover_voice("syllable_" + silaba.to_lower())

func verificar_resposta(resposta: String) -> void:
	if respondendo or fase_atual >= fases.size():
		return
	respondendo = true
	var fase = fases[fase_atual]

	for botao in [btn1, btn2, btn3]:
		botao.disabled = true

	audio.stop_voice()
	audio.play_voice("syllable_" + resposta.to_lower())

	if resposta == resposta_correta:
		metrics.registrar_tentativa(fase["animal"], true)
		lbl_palavra.text = fase["animal"]
		instruction_label.text = "Muito bem!"
		estilizar_painel(caixa_palavra, Color(0.65, 1.0, 0.55))
		await audio.speak_and_wait("feedback_correct", 0.6)
		audio.play_voice("animal_" + fase["audio"])
		await get_tree().create_timer(1.0).timeout
		estilizar_painel(caixa_palavra, Color.WHITE)
		fase_atual += 1
		carregar_fase()
	else:
		metrics.registrar_tentativa(fase["animal"], false)
		lbl_palavra.text = resposta + fase["animal"].substr(2)
		instruction_label.text = "Tente outra vez."
		estilizar_painel(caixa_palavra, Color(1.0, 0.65, 0.65))
		await audio.speak_and_wait("feedback_try_again", 0.8)
		await get_tree().create_timer(0.4).timeout
		estilizar_painel(caixa_palavra, Color.WHITE)
		carregar_fase()

func atualizar_progresso() -> void:
	var texto := ""
	for i in range(fases.size()):
		texto += "●" if i < fase_atual else "○"
		if i < fases.size() - 1:
			texto += "   "
	progress_label.text = texto

func finalizar_jogo() -> void:
	metrics.finalizar_sessao()
	progress_label.text = "●   ●   ●   ●   ●   ●   ●"
	lbl_palavra.text = "PARABÉNS!"
	instruction_label.text = "Você completou o Zoológico das Sílabas!"
	caixa_animal.hide()
	btn1.hide()
	btn2.hide()
	btn3.hide()
	btn_reiniciar.show()
	btn_menu_final.show()
	estilizar_painel(caixa_palavra, Color(0.72, 1.0, 0.62))
	criar_confetes()
	audio.play_voice("final_congratulations")

func criar_confetes() -> void:
	var tela := get_viewport_rect().size
	for i in range(32):
		var confete := ColorRect.new()
		confete.size = Vector2(randf_range(8.0, 18.0), randf_range(8.0, 18.0))
		confete.color = Color.from_hsv(randf(), 0.75, 1.0)
		confete.position = Vector2(randf_range(0.0, tela.x), randf_range(-250.0, -20.0))
		confete.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_child(confete)
		var tween := create_tween()
		tween.tween_property(confete, "position:y", tela.y + 40.0, randf_range(2.2, 4.2))
		tween.tween_callback(confete.queue_free)

func reiniciar_jogo() -> void:
	metrics.iniciar_sessao()
	fase_atual = 0
	btn_reiniciar.hide()
	btn_menu_final.hide()
	btn1.show()
	btn2.show()
	btn3.show()
	estilizar_painel(caixa_palavra, Color.WHITE)
	carregar_fase()

func abrir_tutorial() -> void:
	audio.stop_voice()
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")

func voltar_menu() -> void:
	audio.stop_voice()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func toggle_volume_panel() -> void:
	volume_panel.visible = not volume_panel.visible

func estilizar_painel(painel: Panel, cor: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(25)
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 10
	estilo.shadow_offset = Vector2(8, 8)
	painel.add_theme_stylebox_override("panel", estilo)

func estilizar_botao(botao: Button) -> void:
	botao.add_theme_font_size_override("font_size", 52)
	botao.add_theme_color_override("font_color", Color.BLACK)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
	botao.add_theme_color_override("font_focus_color", Color.BLACK)
	botao.add_theme_color_override("font_disabled_color", Color.BLACK)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.WHITE
	normal.border_color = Color.BLACK
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(22)
	normal.shadow_color = Color(0, 0, 0, 0.35)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(6, 6)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.85, 0.95, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.75, 0.9, 1.0)

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", pressed)
