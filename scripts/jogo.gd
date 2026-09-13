extends Control

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const VOLUME_ICON := preload("res://audio/icons/volume.png")
const MUTED_ICON := preload("res://audio/icons/muted.png")

@onready var layout: Control = $Layout
@onready var fundo_jogo: TextureRect = $Layout/FundoJogo
@onready var caixa_palavra: Panel = $Layout/CaixaPalavra
@onready var lbl_palavra: Label = $Layout/CaixaPalavra/LblPalavra
@onready var caixa_animal: Panel = $Layout/CaixaAnimal
@onready var img_animal: TextureRect = $Layout/CaixaAnimal/ImgAnimal
@onready var btn1: Button = $Layout/Btn1
@onready var btn2: Button = $Layout/Btn2
@onready var btn3: Button = $Layout/Btn3
@onready var btn_reiniciar: Button = $Layout/BtnReiniciar

var audio: AccessibilityAudio
var fase_atual := 0
var resposta_correta := ""
var respondendo := false
var opcoes_atuais: Array = []

var progress_container: HBoxContainer
var instruction_label: Label
var btn_voltar: Button
var btn_ajuda: Button
var btn_repetir: Button
var btn_volume: Button
var volume_panel: Panel
var volume_slider: HSlider
var btn_menu_final: Button

var fases = [
	{"animal": "CACHORRO", "incompleto": "__CHORRO", "silaba": "CA", "opcoes": ["CA", "BA", "PA"], "imagem": "res://img/cachorro.png"},
	{"animal": "GATO", "incompleto": "__TO", "silaba": "GA", "opcoes": ["PA", "GA", "CA"], "imagem": "res://img/gato.png"},
	{"animal": "MACACO", "incompleto": "__CACO", "silaba": "MA", "opcoes": ["MA", "PA", "TA"], "imagem": "res://img/macaco.png"},
	{"animal": "BALEIA", "incompleto": "__LEIA", "silaba": "BA", "opcoes": ["BA", "GA", "LA"], "imagem": "res://img/baleia.png"},
	{"animal": "CAVALO", "incompleto": "__VALO", "silaba": "CA", "opcoes": ["CA", "SA", "RA"], "imagem": "res://img/cavalo.png"},
	{"animal": "GALINHA", "incompleto": "__LINHA", "silaba": "GA", "opcoes": ["MA", "GA", "TA"], "imagem": "res://img/galinha.png"},
	{"animal": "TARTARUGA", "incompleto": "__RTARUGA", "silaba": "TA", "opcoes": ["TA", "CA", "FA"], "imagem": "res://img/tartaruga.png"}
]

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	configurar_layout()
	estilizar_interface()
	criar_controles_acessibilidade()

	btn1.pressed.connect(func(): verificar_resposta(btn1, btn1.text))
	btn2.pressed.connect(func(): verificar_resposta(btn2, btn2.text))
	btn3.pressed.connect(func(): verificar_resposta(btn3, btn3.text))
	btn_reiniciar.pressed.connect(reiniciar_jogo)

	btn_reiniciar.hide()
	carregar_fase(true)

func configurar_layout() -> void:
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo_jogo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo_jogo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo_jogo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	caixa_animal.set_anchors_preset(Control.PRESET_CENTER)
	caixa_animal.offset_left = -225
	caixa_animal.offset_top = -430
	caixa_animal.offset_right = 225
	caixa_animal.offset_bottom = 20
	caixa_animal.clip_contents = true
	img_animal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img_animal.offset_left = 16
	img_animal.offset_top = 16
	img_animal.offset_right = -16
	img_animal.offset_bottom = -16
	img_animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_animal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa_animal.gui_input.connect(_on_caixa_animal_gui_input)
	caixa_animal.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	caixa_animal.tooltip_text = "Clique para ouvir o nome do animal"

	caixa_palavra.set_anchors_preset(Control.PRESET_CENTER)
	caixa_palavra.offset_left = -280
	caixa_palavra.offset_top = 60
	caixa_palavra.offset_right = 280
	caixa_palavra.offset_bottom = 210
	lbl_palavra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl_palavra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_palavra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	configurar_botao_opcao(btn1, -415)
	configurar_botao_opcao(btn2, 0)
	configurar_botao_opcao(btn3, 415)

	btn_reiniciar.set_anchors_preset(Control.PRESET_CENTER)
	btn_reiniciar.offset_left = -440
	btn_reiniciar.offset_top = 285
	btn_reiniciar.offset_right = -10
	btn_reiniciar.offset_bottom = 395
	btn_reiniciar.text = "JOGAR DE NOVO"

func configurar_botao_opcao(botao: Button, deslocamento_x: float) -> void:
	botao.set_anchors_preset(Control.PRESET_CENTER)
	botao.offset_left = deslocamento_x - 115
	botao.offset_top = 285
	botao.offset_right = deslocamento_x + 115
	botao.offset_bottom = 405

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
	progress_container = HBoxContainer.new()
	progress_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progress_container.offset_left = -125
	progress_container.offset_top = 28
	progress_container.offset_right = 125
	progress_container.offset_bottom = 54
	progress_container.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_container.add_theme_constant_override("separation", 14)
	layout.add_child(progress_container)
	for i in range(fases.size()):
		progress_container.add_child(criar_bolinha_progresso(false))

	instruction_label = Label.new()
	instruction_label.set_anchors_preset(Control.PRESET_CENTER)
	instruction_label.offset_left = -425
	instruction_label.offset_top = 220
	instruction_label.offset_right = 425
	instruction_label.offset_bottom = 276
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 28)
	instruction_label.add_theme_color_override("font_color", Color.BLACK)
	layout.add_child(instruction_label)

	btn_voltar = criar_botao_topo("↩", Vector2(24, 24))
	btn_voltar.pressed.connect(voltar_menu)
	btn_voltar.mouse_entered.connect(func(): audio.play_voice("ui_back"))

	btn_ajuda = criar_botao_topo("?", Vector2(124, 24))
	btn_ajuda.pressed.connect(abrir_tutorial)
	btn_ajuda.tooltip_text = "Como jogar"
	btn_ajuda.mouse_entered.connect(func(): audio.play_voice("ui_help"))

	btn_repetir = criar_botao_topo("🔊", Vector2(224, 24))
	btn_repetir.pressed.connect(repetir_instrucao)
	btn_repetir.tooltip_text = "Ouvir o nome do animal novamente"

	btn_volume = Button.new()
	btn_volume.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_volume.offset_left = -118
	btn_volume.offset_top = 24
	btn_volume.offset_right = -28
	btn_volume.offset_bottom = 96
	btn_volume.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estilizar_botao_pequeno(btn_volume)
	atualizar_icone_volume()
	btn_volume.pressed.connect(toggle_volume_panel)
	btn_volume.mouse_entered.connect(func(): audio.play_voice("ui_volume"))
	layout.add_child(btn_volume)

	volume_panel = Panel.new()
	volume_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	volume_panel.offset_left = -330
	volume_panel.offset_top = 108
	volume_panel.offset_right = -28
	volume_panel.offset_bottom = 198
	volume_panel.visible = false
	estilizar_painel(volume_panel, Color(1, 1, 1, 0.97))
	layout.add_child(volume_panel)

	volume_slider = HSlider.new()
	volume_slider.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	volume_slider.offset_left = 28
	volume_slider.offset_top = 24
	volume_slider.offset_right = -28
	volume_slider.offset_bottom = -24
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = audio.load_saved_volume()
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_panel.add_child(volume_slider)

	btn_menu_final = Button.new()
	btn_menu_final.text = "VOLTAR AO MENU"
	btn_menu_final.set_anchors_preset(Control.PRESET_CENTER)
	btn_menu_final.offset_left = 10
	btn_menu_final.offset_top = 285
	btn_menu_final.offset_right = 440
	btn_menu_final.offset_bottom = 395
	btn_menu_final.visible = false
	estilizar_botao(btn_menu_final)
	btn_menu_final.add_theme_font_size_override("font_size", 32)
	btn_menu_final.pressed.connect(voltar_menu)
	layout.add_child(btn_menu_final)

func criar_botao_topo(texto: String, posicao: Vector2) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.size = Vector2(90, 72)
	botao.position = posicao
	estilizar_botao_pequeno(botao)
	layout.add_child(botao)
	return botao

func carregar_fase(novas_opcoes: bool = true) -> void:
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
	instruction_label.text = ""
	estilizar_painel(caixa_palavra, Color.WHITE)
	img_animal.texture = load(fase["imagem"])
	atualizar_progresso()

	if novas_opcoes or opcoes_atuais.is_empty():
		opcoes_atuais = fase["opcoes"].duplicate()
		opcoes_atuais.shuffle()
	btn1.text = opcoes_atuais[0]
	btn2.text = opcoes_atuais[1]
	btn3.text = opcoes_atuais[2]

	for botao in [btn1, btn2, btn3]:
		botao.disabled = false
		botao.show()
		aplicar_estado_botao(botao, Color.WHITE)

	call_deferred("anunciar_fase")

func anunciar_fase() -> void:
	if fase_atual >= fases.size():
		return
	var fase = fases[fase_atual]
	await audio.play_word_and_wait(fase["animal"], 1.0)

func repetir_instrucao() -> void:
	if fase_atual >= fases.size():
		audio.play_voice("final_congratulations")
		return
	anunciar_fase()

func verificar_resposta(botao_escolhido: Button, resposta: String) -> void:
	if respondendo or fase_atual >= fases.size():
		return
	respondendo = true
	var fase = fases[fase_atual]
	for botao in [btn1, btn2, btn3]:
		botao.disabled = true

	await audio.play_syllable_and_wait(resposta, 0.65)

	if resposta == resposta_correta:
		aplicar_estado_botao(botao_escolhido, Color(0.65, 1.0, 0.55))
		lbl_palavra.text = fase["animal"]
		instruction_label.text = "Parabéns!"
		estilizar_painel(caixa_palavra, Color(0.65, 1.0, 0.55))
		await audio.speak_and_wait("feedback_correct", 1.2)
		await audio.play_word_and_wait(fase["animal"], 1.0)
		await get_tree().create_timer(0.45).timeout
		fase_atual += 1
		opcoes_atuais.clear()
		carregar_fase(true)
	else:
		aplicar_estado_botao(botao_escolhido, Color(1.0, 0.72, 0.68))
		lbl_palavra.text = resposta + fase["animal"].substr(2)
		instruction_label.text = "Tente outra vez."
		estilizar_painel(caixa_palavra, Color(1.0, 0.76, 0.72))
		await audio.speak_and_wait("feedback_try_again", 1.25)
		await get_tree().create_timer(0.25).timeout
		lbl_palavra.text = fase["incompleto"]
		estilizar_painel(caixa_palavra, Color.WHITE)
		for botao in [btn1, btn2, btn3]:
			botao.disabled = false
			aplicar_estado_botao(botao, Color.WHITE)
		respondendo = false

func atualizar_progresso() -> void:
	for i in range(progress_container.get_child_count()):
		var dot := progress_container.get_child(i) as Panel
		if dot != null:
			dot.add_theme_stylebox_override("panel", criar_estilo_bolinha(i < fase_atual))

func criar_bolinha_progresso(ativa: bool) -> Panel:
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(20, 20)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_stylebox_override("panel", criar_estilo_bolinha(ativa))
	return dot

func criar_estilo_bolinha(ativa: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.10, 0.10, 0.10, 1.0) if ativa else Color(1, 1, 1, 0.36)
	estilo.border_color = Color(0.18, 0.18, 0.18)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	return estilo

func finalizar_jogo() -> void:
	for i in range(progress_container.get_child_count()):
		var dot := progress_container.get_child(i) as Panel
		if dot != null:
			dot.add_theme_stylebox_override("panel", criar_estilo_bolinha(true))
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
	fase_atual = 0
	opcoes_atuais.clear()
	btn_reiniciar.hide()
	btn_menu_final.hide()
	btn1.show()
	btn2.show()
	btn3.show()
	carregar_fase(true)

func _on_caixa_animal_gui_input(event: InputEvent) -> void:
	if fase_atual >= fases.size():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		audio.play_word(str(fases[fase_atual]["animal"]))
	elif event is InputEventScreenTouch and event.pressed:
		audio.play_word(str(fases[fase_atual]["animal"]))

func abrir_tutorial() -> void:
	audio.stop_voice()
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")

func voltar_menu() -> void:
	audio.stop_voice()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func toggle_volume_panel() -> void:
	volume_panel.visible = not volume_panel.visible

func _on_volume_changed(value: float) -> void:
	audio.save_master_volume(value)
	atualizar_icone_volume()

func atualizar_icone_volume() -> void:
	btn_volume.icon = MUTED_ICON if audio.is_muted() else VOLUME_ICON
	btn_volume.tooltip_text = "Ativar som" if audio.is_muted() else "Controle de volume"

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
	botao.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0.70))
	aplicar_estado_botao(botao, Color.WHITE)

func estilizar_botao_pequeno(botao: Button) -> void:
	estilizar_botao(botao)
	botao.add_theme_font_size_override("font_size", 30)
	botao.add_theme_constant_override("icon_max_width", 48)

func aplicar_estado_botao(botao: Button, cor: Color) -> void:
	var normal := criar_estilo_botao(cor)
	var hover := criar_estilo_botao(cor.lightened(0.06))
	var pressed := criar_estilo_botao(cor.darkened(0.06))
	var disabled := normal.duplicate()
	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", pressed)
	botao.add_theme_stylebox_override("disabled", disabled)

func criar_estilo_botao(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(22)
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 8
	estilo.shadow_offset = Vector2(6, 6)
	return estilo
