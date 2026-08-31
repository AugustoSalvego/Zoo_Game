extends Control

signal tutorial_correct_choice

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const SETTINGS_PATH := "user://zoo_settings.cfg"

var audio
var tutorial_ativo := true
var current_voice_key := "tutorial_welcome"

var fundo: TextureRect
var instruction_panel: Panel
var instruction_label: Label
var animal_panel: Panel
var animal_image: TextureRect
var word_panel: Panel
var word_label: Label
var btn_ca: Button
var btn_ba: Button
var btn_pa: Button
var btn_skip: Button
var btn_repeat: Button
var btn_volume: Button
var volume_panel: Panel
var volume_slider: HSlider

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	criar_interface()
	await get_tree().process_frame
	executar_tutorial()

func criar_interface() -> void:
	var tela := get_viewport_rect().size

	fundo = TextureRect.new()
	fundo.texture = load("res://img/fundo_jogo.png")
	fundo.position = Vector2.ZERO
	fundo.size = tela
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(fundo)

	instruction_panel = Panel.new()
	instruction_panel.size = Vector2(900, 96)
	instruction_panel.position = Vector2((tela.x - 900) / 2.0, 24)
	estilizar_painel(instruction_panel, Color(1, 1, 1, 0.96))
	add_child(instruction_panel)

	instruction_label = Label.new()
	instruction_label.size = instruction_panel.size
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 34)
	instruction_label.add_theme_color_override("font_color", Color.BLACK)
	instruction_panel.add_child(instruction_label)

	animal_panel = Panel.new()
	animal_panel.size = Vector2(420, 420)
	animal_panel.position = Vector2((tela.x - 420) / 2.0, 150)
	estilizar_painel(animal_panel, Color(0.82, 0.95, 0.82))
	add_child(animal_panel)

	animal_image = TextureRect.new()
	animal_image.texture = load("res://img/cachorro.png")
	animal_image.size = animal_panel.size
	animal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animal_panel.add_child(animal_image)

	word_panel = Panel.new()
	word_panel.size = Vector2(600, 130)
	word_panel.position = Vector2((tela.x - 600) / 2.0, 610)
	estilizar_painel(word_panel, Color.WHITE)
	add_child(word_panel)

	word_label = Label.new()
	word_label.size = word_panel.size
	word_label.text = "__CHORRO"
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.add_theme_font_size_override("font_size", 62)
	word_label.add_theme_color_override("font_color", Color.BLACK)
	word_panel.add_child(word_label)

	btn_ca = criar_opcao("CA", Vector2(430, 800))
	btn_ba = criar_opcao("BA", Vector2(845, 800))
	btn_pa = criar_opcao("PA", Vector2(1260, 800))

	btn_ca.pressed.connect(func(): verificar_tutorial("CA"))
	btn_ba.pressed.connect(func(): verificar_tutorial("BA"))
	btn_pa.pressed.connect(func(): verificar_tutorial("PA"))

	btn_ca.mouse_entered.connect(func(): audio.play_voice("syllable_ca"))
	btn_ba.mouse_entered.connect(func(): audio.play_voice("syllable_ba"))
	btn_pa.mouse_entered.connect(func(): audio.play_voice("syllable_pa"))

	btn_skip = Button.new()
	btn_skip.text = "PULAR"
	btn_skip.size = Vector2(150, 70)
	btn_skip.position = Vector2(24, 24)
	estilizar_botao_pequeno(btn_skip)
	btn_skip.pressed.connect(finalizar_tutorial)
	btn_skip.mouse_entered.connect(func(): audio.play_voice("ui_skip"))
	add_child(btn_skip)

	btn_repeat = Button.new()
	btn_repeat.text = "🔊"
	btn_repeat.size = Vector2(90, 70)
	btn_repeat.position = Vector2(tela.x - 230, 24)
	estilizar_botao_pequeno(btn_repeat)
	btn_repeat.pressed.connect(func(): audio.play_voice(current_voice_key))
	btn_repeat.mouse_entered.connect(func(): audio.play_voice("ui_repeat"))
	add_child(btn_repeat)

	btn_volume = Button.new()
	btn_volume.text = "SOM"
	btn_volume.size = Vector2(110, 70)
	btn_volume.position = Vector2(tela.x - 130, 24)
	estilizar_botao_pequeno(btn_volume)
	btn_volume.pressed.connect(toggle_volume_panel)
	btn_volume.mouse_entered.connect(func(): audio.play_voice("ui_volume"))
	add_child(btn_volume)

	volume_panel = Panel.new()
	volume_panel.size = Vector2(300, 90)
	volume_panel.position = Vector2(tela.x - 330, 108)
	volume_panel.visible = false
	estilizar_painel(volume_panel, Color(1, 1, 1, 0.95))
	add_child(volume_panel)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = audio.load_saved_volume()
	volume_slider.size = Vector2(245, 40)
	volume_slider.position = Vector2(28, 24)
	volume_slider.value_changed.connect(func(value: float): audio.save_master_volume(value))
	volume_panel.add_child(volume_slider)

func executar_tutorial() -> void:
	bloquear_opcoes(true)

	await falar_e_mostrar("tutorial_welcome", "Vamos aprender a jogar!", 2.0)
	if not tutorial_ativo: return

	destacar(animal_panel, Color(1.0, 0.95, 0.55))
	await falar_e_mostrar("tutorial_look_animal", "Olhe o animal.", 2.0)
	if not tutorial_ativo: return

	await falar_e_mostrar("animal_cachorro", "Este é um cachorro.", 1.8)
	if not tutorial_ativo: return

	destacar(word_panel, Color(1.0, 0.95, 0.55))
	await falar_e_mostrar("tutorial_word_missing", "Uma parte da palavra está faltando.", 2.2)
	if not tutorial_ativo: return

	bloquear_opcoes(false)
	destacar_botao(btn_ca)
	await falar_e_mostrar("tutorial_choose_ca", "Escolha a sílaba CA.", 2.0)
	if not tutorial_ativo: return

	instruction_label.text = "Agora clique em CA."
	current_voice_key = "tutorial_click_ca"
	audio.play_voice(current_voice_key)
	await tutorial_correct_choice
	if not tutorial_ativo: return

	word_label.text = "CACHORRO"
	destacar(word_panel, Color(0.65, 1.0, 0.55))
	await falar_e_mostrar("feedback_correct", "Muito bem! Você acertou!", 1.8)
	if not tutorial_ativo: return

	await falar_e_mostrar("tutorial_your_turn", "Agora é sua vez!", 1.8)
	if tutorial_ativo:
		finalizar_tutorial()

func verificar_tutorial(resposta: String) -> void:
	audio.stop_voice()
	if resposta == "CA":
		bloquear_opcoes(true)
		tutorial_correct_choice.emit()
	else:
		instruction_label.text = "Tente outra vez. Procure CA."
		current_voice_key = "feedback_try_again"
		audio.play_voice(current_voice_key)
		destacar_botao(btn_ca)

func falar_e_mostrar(key: String, texto: String, fallback: float) -> void:
	current_voice_key = key
	instruction_label.text = texto
	await audio.speak_and_wait(key, fallback)

func finalizar_tutorial() -> void:
	if not tutorial_ativo:
		return
	tutorial_ativo = false
	audio.stop_voice()
	marcar_tutorial_visto()
	get_tree().change_scene_to_file("res://scenes/Jogo.tscn")

func marcar_tutorial_visto() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("tutorial", "seen", true)
	config.save(SETTINGS_PATH)

func criar_opcao(texto: String, posicao: Vector2) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.size = Vector2(230, 120)
	botao.position = posicao
	estilizar_botao(botao)
	add_child(botao)
	return botao

func bloquear_opcoes(bloquear: bool) -> void:
	btn_ca.disabled = bloquear
	btn_ba.disabled = bloquear
	btn_pa.disabled = bloquear

func destacar(painel: Panel, cor: Color) -> void:
	estilizar_painel(painel, cor)

func destacar_botao(botao: Button) -> void:
	var destaque := StyleBoxFlat.new()
	destaque.bg_color = Color(1.0, 0.95, 0.45)
	destaque.border_color = Color.BLACK
	destaque.set_border_width_all(6)
	destaque.set_corner_radius_all(22)
	botao.add_theme_stylebox_override("normal", destaque)

func toggle_volume_panel() -> void:
	volume_panel.visible = not volume_panel.visible

func estilizar_painel(painel: Panel, cor: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(24)
	estilo.shadow_color = Color(0, 0, 0, 0.3)
	estilo.shadow_size = 8
	estilo.shadow_offset = Vector2(5, 5)
	painel.add_theme_stylebox_override("panel", estilo)

func estilizar_botao(botao: Button) -> void:
	botao.add_theme_font_size_override("font_size", 52)
	botao.add_theme_color_override("font_color", Color.BLACK)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
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

func estilizar_botao_pequeno(botao: Button) -> void:
	estilizar_botao(botao)
	botao.add_theme_font_size_override("font_size", 26)
