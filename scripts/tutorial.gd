extends Control

signal tutorial_correct_choice

const AccessibilityAudio = preload(
	"res://scripts/accessibility_audio.gd"
)

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

	configurar_layout_mobile()

	await get_tree().process_frame

	executar_tutorial()


func criar_interface() -> void:
	# -------------------------
	# FUNDO
	# -------------------------

	fundo = TextureRect.new()

	fundo.texture = load(
		"res://img/fundo_jogo.png"
	)

	fundo.position = Vector2.ZERO
	fundo.size = get_viewport_rect().size

	fundo.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	fundo.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)

	fundo.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(fundo)

	# -------------------------
	# INSTRUÇÃO
	# -------------------------

	instruction_panel = Panel.new()

	estilizar_painel(
		instruction_panel,
		Color(1, 1, 1, 0.96)
	)

	add_child(instruction_panel)

	instruction_label = Label.new()

	instruction_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	instruction_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	instruction_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	instruction_label.add_theme_color_override(
		"font_color",
		Color.BLACK
	)

	instruction_panel.add_child(
		instruction_label
	)

	# -------------------------
	# ANIMAL
	# -------------------------

	animal_panel = Panel.new()

	estilizar_painel(
		animal_panel,
		Color(0.82, 0.95, 0.82)
	)

	add_child(animal_panel)

	animal_image = TextureRect.new()

	animal_image.texture = load(
		"res://img/cachorro.png"
	)

	animal_image.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	animal_image.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	animal_image.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	animal_panel.add_child(
		animal_image
	)

	# -------------------------
	# PALAVRA
	# -------------------------

	word_panel = Panel.new()

	estilizar_painel(
		word_panel,
		Color.WHITE
	)

	add_child(word_panel)

	word_label = Label.new()

	word_label.text = "__CHORRO"

	word_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	word_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	word_label.add_theme_color_override(
		"font_color",
		Color.BLACK
	)

	word_panel.add_child(
		word_label
	)

	# -------------------------
	# OPÇÕES
	# -------------------------

	btn_ca = criar_opcao("CA")
	btn_ba = criar_opcao("BA")
	btn_pa = criar_opcao("PA")

	btn_ca.pressed.connect(
		func():
			verificar_tutorial("CA")
	)

	btn_ba.pressed.connect(
		func():
			verificar_tutorial("BA")
	)

	btn_pa.pressed.connect(
		func():
			verificar_tutorial("PA")
	)

	# -------------------------
	# PULAR
	# -------------------------

	btn_skip = Button.new()

	btn_skip.text = "PULAR"

	estilizar_botao(
		btn_skip,
		24.0
	)

	btn_skip.pressed.connect(
		finalizar_tutorial
	)

	btn_skip.pressed.connect(
		func():
			audio.play_voice("ui_skip")
	)

	add_child(btn_skip)

	# -------------------------
	# REPETIR
	# -------------------------

	btn_repeat = Button.new()

	btn_repeat.text = "🔊"

	estilizar_botao(
		btn_repeat,
		26.0
	)

	btn_repeat.pressed.connect(
		func():
			audio.play_voice(
				current_voice_key
			)
	)

	add_child(btn_repeat)

	# -------------------------
	# VOLUME
	# -------------------------

	btn_volume = Button.new()

	btn_volume.text = "SOM"

	estilizar_botao(
		btn_volume,
		22.0
	)

	btn_volume.pressed.connect(
		toggle_volume_panel
	)

	btn_volume.pressed.connect(
		func():
			audio.play_voice("ui_volume")
	)

	add_child(btn_volume)

	# -------------------------
	# PAINEL DE VOLUME
	# -------------------------

	volume_panel = Panel.new()

	volume_panel.visible = false

	estilizar_painel(
		volume_panel,
		Color(1, 1, 1, 0.96)
	)

	add_child(volume_panel)

	volume_slider = HSlider.new()

	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = (
		audio.load_saved_volume()
	)

	volume_slider.value_changed.connect(
		func(value: float):
			audio.save_master_volume(value)
	)

	volume_panel.add_child(
		volume_slider
	)


func configurar_layout_mobile() -> void:
	var tela := get_viewport_rect().size

	var margem := 20.0

	# Escala vertical adaptativa.
	var compacto := tela.y < 800.0

	var tamanho_animal := clampf(
		minf(
			tela.x - margem * 2.0,
			tela.y * 0.235
		),
		160.0,
		300.0
	)

	var altura_palavra := (
		80.0 if compacto else 100.0
	)

	var altura_instrucao := (
		58.0 if compacto else 70.0
	)

	var altura_opcao := (
		62.0 if compacto else 78.0
	)

	var espaco := (
		8.0 if compacto else 12.0
	)

	# -------------------------
	# BOTÕES SUPERIORES
	# -------------------------

	btn_skip.size = Vector2(
		86.0,
		58.0
	)

	btn_skip.position = Vector2(
		margem,
		18.0
	)

	btn_repeat.size = Vector2(
		70.0,
		58.0
	)

	btn_repeat.position = Vector2(
		tela.x - 170.0,
		18.0
	)

	btn_volume.size = Vector2(
		90.0,
		58.0
	)

	btn_volume.position = Vector2(
		tela.x - 110.0,
		18.0
	)

	# -------------------------
	# INSTRUÇÃO
	# -------------------------

	var instrucao_largura := minf(
		tela.x - margem * 2.0,
		650.0
	)

	instruction_panel.size = Vector2(
		instrucao_largura,
		altura_instrucao
	)

	instruction_panel.position = Vector2(
		(tela.x - instrucao_largura) / 2.0,
		88.0
	)

	instruction_label.size = (
		instruction_panel.size
	)

	instruction_label.add_theme_font_size_override(
		"font_size",
		22 if compacto else 26
	)

	# -------------------------
	# ANIMAL
	# -------------------------

	var animal_y := (
		instruction_panel.position.y
		+ instruction_panel.size.y
		+ 18.0
	)

	animal_panel.size = Vector2(
		tamanho_animal,
		tamanho_animal
	)

	animal_panel.position = Vector2(
		(tela.x - tamanho_animal) / 2.0,
		animal_y
	)

	animal_image.position = Vector2.ZERO
	animal_image.size = animal_panel.size

	# -------------------------
	# PALAVRA
	# -------------------------

	var palavra_y := (
		animal_y
		+ tamanho_animal
		+ 14.0
	)

	var palavra_largura := minf(
		tela.x - margem * 2.0,
		650.0
	)

	word_panel.size = Vector2(
		palavra_largura,
		altura_palavra
	)

	word_panel.position = Vector2(
		(tela.x - palavra_largura) / 2.0,
		palavra_y
	)

	word_label.position = Vector2.ZERO
	word_label.size = word_panel.size

	word_label.add_theme_font_size_override(
		"font_size",
		42 if compacto else 54
	)

	# -------------------------
	# BOTÕES DE SÍLABA
	# -------------------------

	var opcoes_y := (
		palavra_y
		+ altura_palavra
		+ 18.0
	)

	var largura_opcao := minf(
		tela.x - margem * 2.0,
		620.0
	)

	var x_opcao := (
		tela.x - largura_opcao
	) / 2.0

	btn_ca.size = Vector2(
		largura_opcao,
		altura_opcao
	)

	btn_ba.size = btn_ca.size
	btn_pa.size = btn_ca.size

	btn_ca.position = Vector2(
		x_opcao,
		opcoes_y
	)

	btn_ba.position = Vector2(
		x_opcao,
		opcoes_y
		+ altura_opcao
		+ espaco
	)

	btn_pa.position = Vector2(
		x_opcao,
		opcoes_y
		+ (altura_opcao + espaco) * 2.0
	)

	for botao in [
		btn_ca,
		btn_ba,
		btn_pa
	]:
		estilizar_botao(
			botao,
			32 if compacto else 40
		)

	# -------------------------
	# VOLUME
	# -------------------------

	var volume_largura := minf(
		tela.x - 40.0,
		330.0
	)

	volume_panel.size = Vector2(
		volume_largura,
		94.0
	)

	volume_panel.position = Vector2(
		tela.x - volume_largura - 20.0,
		86.0
	)

	volume_slider.size = Vector2(
		volume_largura - 40.0,
		42.0
	)

	volume_slider.position = Vector2(
		20.0,
		26.0
	)


func executar_tutorial() -> void:
	bloquear_opcoes(true)

	await falar_e_mostrar(
		"tutorial_welcome",
		"Vamos aprender a jogar!",
		2.0
	)

	if not tutorial_ativo:
		return

	destacar(
		animal_panel,
		Color(1.0, 0.95, 0.55)
	)

	await falar_e_mostrar(
		"tutorial_look_animal",
		"Olhe o animal.",
		2.0
	)

	if not tutorial_ativo:
		return

	await falar_e_mostrar(
		"animal_cachorro",
		"Este é um cachorro.",
		1.8
	)

	if not tutorial_ativo:
		return

	destacar(
		word_panel,
		Color(1.0, 0.95, 0.55)
	)

	await falar_e_mostrar(
		"tutorial_word_missing",
		"Uma parte da palavra está faltando.",
		2.2
	)

	if not tutorial_ativo:
		return

	bloquear_opcoes(false)

	destacar_botao(btn_ca)

	await falar_e_mostrar(
		"tutorial_choose_ca",
		"Escolha a sílaba CA.",
		2.0
	)

	if not tutorial_ativo:
		return

	instruction_label.text = (
		"Agora toque em CA."
	)

	current_voice_key = (
		"tutorial_click_ca"
	)

	audio.play_voice(
		current_voice_key
	)

	await tutorial_correct_choice

	if not tutorial_ativo:
		return

	word_label.text = "CACHORRO"

	destacar(
		word_panel,
		Color(0.65, 1.0, 0.55)
	)

	await falar_e_mostrar(
		"feedback_correct",
		"Muito bem! Você acertou!",
		1.8
	)

	if not tutorial_ativo:
		return

	await falar_e_mostrar(
		"tutorial_your_turn",
		"Agora é sua vez!",
		1.8
	)

	if tutorial_ativo:
		finalizar_tutorial()


func verificar_tutorial(
	resposta: String
) -> void:

	audio.stop_voice()

	if resposta == "CA":
		bloquear_opcoes(true)

		tutorial_correct_choice.emit()

	else:
		instruction_label.text = (
			"Tente outra vez. Procure CA."
		)

		current_voice_key = (
			"feedback_try_again"
		)

		audio.play_voice(
			current_voice_key
		)

		destacar_botao(
			btn_ca
		)


func falar_e_mostrar(
	key: String,
	texto: String,
	fallback: float
) -> void:

	current_voice_key = key

	instruction_label.text = texto

	await audio.speak_and_wait(
		key,
		fallback
	)


func finalizar_tutorial() -> void:
	if not tutorial_ativo:
		return

	tutorial_ativo = false

	audio.stop_voice()

	marcar_tutorial_visto()

	get_tree().change_scene_to_file(
		"res://scenes/Jogo.tscn"
	)


func marcar_tutorial_visto() -> void:
	var config := ConfigFile.new()

	config.load(SETTINGS_PATH)

	config.set_value(
		"tutorial",
		"seen",
		true
	)

	config.save(
		SETTINGS_PATH
	)


func criar_opcao(
	texto: String
) -> Button:

	var botao := Button.new()

	botao.text = texto

	estilizar_botao(
		botao,
		38.0
	)

	add_child(botao)

	return botao


func bloquear_opcoes(
	bloquear: bool
) -> void:

	btn_ca.disabled = bloquear
	btn_ba.disabled = bloquear
	btn_pa.disabled = bloquear


func destacar(
	painel: Panel,
	cor: Color
) -> void:

	estilizar_painel(
		painel,
		cor
	)


func destacar_botao(
	botao: Button
) -> void:

	var destaque := StyleBoxFlat.new()

	destaque.bg_color = Color(
		1.0,
		0.95,
		0.45
	)

	destaque.border_color = Color.BLACK

	destaque.set_border_width_all(6)
	destaque.set_corner_radius_all(22)

	botao.add_theme_stylebox_override(
		"normal",
		destaque
	)


func toggle_volume_panel() -> void:
	volume_panel.visible = (
		not volume_panel.visible
	)


func estilizar_painel(
	painel: Panel,
	cor: Color
) -> void:

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = cor
	estilo.border_color = Color.BLACK

	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(24)

	estilo.shadow_color = Color(
		0,
		0,
		0,
		0.3
	)

	estilo.shadow_size = 8
	estilo.shadow_offset = Vector2(
		5,
		5
	)

	painel.add_theme_stylebox_override(
		"panel",
		estilo
	)


func estilizar_botao(
	botao: Button,
	tamanho_fonte: float = 40.0
) -> void:

	botao.add_theme_font_size_override(
		"font_size",
		int(tamanho_fonte)
	)

	botao.add_theme_color_override(
		"font_color",
		Color.BLACK
	)

	botao.add_theme_color_override(
		"font_pressed_color",
		Color.BLACK
	)

	botao.add_theme_color_override(
		"font_focus_color",
		Color.BLACK
	)

	var normal := StyleBoxFlat.new()

	normal.bg_color = Color.WHITE
	normal.border_color = Color.BLACK

	normal.set_border_width_all(5)
	normal.set_corner_radius_all(22)

	normal.shadow_color = Color(
		0,
		0,
		0,
		0.35
	)

	normal.shadow_size = 8
	normal.shadow_offset = Vector2(
		6,
		6
	)

	var hover := normal.duplicate()

	hover.bg_color = Color(
		0.85,
		0.95,
		1.0
	)

	var pressed := normal.duplicate()

	pressed.bg_color = Color(
		0.75,
		0.90,
		1.0
	)

	botao.add_theme_stylebox_override(
		"normal",
		normal
	)

	botao.add_theme_stylebox_override(
		"hover",
		hover
	)

	botao.add_theme_stylebox_override(
		"pressed",
		pressed
	)
