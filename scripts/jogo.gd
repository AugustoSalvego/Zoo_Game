extends Control

const AccessibilityAudio = preload(
	"res://scripts/accessibility_audio.gd"
)

const SETTINGS_PATH := "user://zoo_settings.cfg"


var audio: AccessibilityAudio

var fase_atual := 0
var resposta_correta := ""
var respondendo := false


# ============================================================
# INTERFACE
# ============================================================

var main_margin: MarginContainer
var main_column: VBoxContainer

var header: HBoxContainer
var progress_label: Label

var animal_panel: PanelContainer
var animal_image: TextureRect

var word_panel: PanelContainer
var word_label: Label

var instruction_label: Label

var options_column: VBoxContainer

var btn1: Button
var btn2: Button
var btn3: Button

var footer: HBoxContainer

var btn_voltar: Button
var btn_ajuda: Button
var btn_repetir: Button
var btn_volume: Button

var volume_panel: PanelContainer
var volume_slider: HSlider

var final_buttons: VBoxContainer
var btn_reiniciar: Button
var btn_menu_final: Button


# ============================================================
# FASES
# ============================================================

var fases = [
	{
		"animal": "CACHORRO",
		"audio": "cachorro",
		"incompleto": "__CHORRO",
		"silaba": "CA",
		"opcoes": ["CA", "BA", "PA"],
		"imagem": "res://img/cachorro.png"
	},
	{
		"animal": "GATO",
		"audio": "gato",
		"incompleto": "__TO",
		"silaba": "GA",
		"opcoes": ["PA", "GA", "CA"],
		"imagem": "res://img/gato.png"
	},
	{
		"animal": "MACACO",
		"audio": "macaco",
		"incompleto": "__CACO",
		"silaba": "MA",
		"opcoes": ["MA", "PA", "TA"],
		"imagem": "res://img/macaco.png"
	},
	{
		"animal": "BALEIA",
		"audio": "baleia",
		"incompleto": "__LEIA",
		"silaba": "BA",
		"opcoes": ["BA", "GA", "LA"],
		"imagem": "res://img/baleia.png"
	},
	{
		"animal": "CAVALO",
		"audio": "cavalo",
		"incompleto": "__VALO",
		"silaba": "CA",
		"opcoes": ["CA", "SA", "RA"],
		"imagem": "res://img/cavalo.png"
	},
	{
		"animal": "GALINHA",
		"audio": "galinha",
		"incompleto": "__LINHA",
		"silaba": "GA",
		"opcoes": ["MA", "GA", "TA"],
		"imagem": "res://img/galinha.png"
	},
	{
		"animal": "TARTARUGA",
		"audio": "tartaruga",
		"incompleto": "__RTARUGA",
		"silaba": "TA",
		"opcoes": ["TA", "CA", "FA"],
		"imagem": "res://img/tartaruga.png"
	}
]


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	audio = AccessibilityAudio.new()
	add_child(audio)

	audio.play_music("game")

	criar_interface()

	carregar_fase()


# ============================================================
# CRIAÇÃO DA INTERFACE
# ============================================================

func criar_interface() -> void:

	# --------------------------------------------------------
	# MARGEM PRINCIPAL
	# --------------------------------------------------------

	main_margin = MarginContainer.new()

	main_margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	main_margin.add_theme_constant_override(
		"margin_left",
		20
	)

	main_margin.add_theme_constant_override(
		"margin_right",
		20
	)

	main_margin.add_theme_constant_override(
		"margin_top",
		16
	)

	main_margin.add_theme_constant_override(
		"margin_bottom",
		16
	)

	add_child(main_margin)


	# --------------------------------------------------------
	# COLUNA PRINCIPAL
	# --------------------------------------------------------

	main_column = VBoxContainer.new()

	main_column.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	main_column.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	main_column.add_theme_constant_override(
		"separation",
		14
	)

	main_margin.add_child(main_column)


	# --------------------------------------------------------
	# HEADER
	# --------------------------------------------------------

	header = HBoxContainer.new()

	header.custom_minimum_size = Vector2(
		0,
		80	)

	header.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	header.add_theme_constant_override(
		"separation",
		8
	)

	main_column.add_child(header)


	btn_voltar = criar_botao(
		"↩",
		28
	)

	btn_voltar.custom_minimum_size = Vector2(
		64,
		60
	)

	btn_voltar.pressed.connect(
		voltar_menu
	)

	header.add_child(btn_voltar)


	btn_ajuda = criar_botao(
		"?",
		28
	)

	btn_ajuda.custom_minimum_size = Vector2(
		64,
		60
	)

	btn_ajuda.pressed.connect(
		abrir_tutorial
	)

	header.add_child(btn_ajuda)


	btn_repetir = criar_botao(
		"🔊",
		26
	)

	btn_repetir.custom_minimum_size = Vector2(
		64,
		60
	)

	btn_repetir.pressed.connect(
		repetir_instrucao
	)

	header.add_child(btn_repetir)


	# Espaçador
	var header_spacer := Control.new()

	header_spacer.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	header.add_child(header_spacer)


	btn_volume = criar_botao(
		"SOM",
		20
	)

	btn_volume.custom_minimum_size = Vector2(
		90,
		60
	)

	btn_volume.pressed.connect(
		toggle_volume_panel
	)

	header.add_child(btn_volume)


	# --------------------------------------------------------
	# PROGRESSO
	# --------------------------------------------------------

	progress_label = Label.new()

	progress_label.custom_minimum_size = Vector2(
		0,
		38
	)

	progress_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	progress_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	progress_label.add_theme_font_size_override(
		"font_size",
		24
	)

	progress_label.add_theme_color_override(
		"font_color",
		Color.BLACK
	)

	main_column.add_child(
		progress_label
	)


	# --------------------------------------------------------
	# ANIMAL
	# --------------------------------------------------------

	var animal_center := CenterContainer.new()

	animal_center.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	animal_center.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	animal_center.custom_minimum_size = Vector2(
		0,
		220
	)

	main_column.add_child(
		animal_center
	)


	animal_panel = PanelContainer.new()

	animal_panel.custom_minimum_size = Vector2(
		190,
		190
	)

	estilizar_painel(
		animal_panel,
		Color(
			0.78,
			0.92,
			0.78
		)
	)

	animal_center.add_child(
		animal_panel
	)


	animal_image = TextureRect.new()

	animal_image.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	animal_image.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	animal_image.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	animal_image.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	animal_image.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	animal_panel.add_child(
		animal_image
	)


	# --------------------------------------------------------
	# PALAVRA
	# --------------------------------------------------------

	word_panel = PanelContainer.new()

	word_panel.custom_minimum_size = Vector2(
		0,
		82
	)

	word_panel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	estilizar_painel(
		word_panel,
		Color.WHITE
	)

	main_column.add_child(
		word_panel
	)


	word_label = Label.new()

	word_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	word_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	word_label.add_theme_font_size_override(
		"font_size",
		42
	)

	word_label.add_theme_color_override(
		"font_color",
		Color.BLACK
	)

	word_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	word_label.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	word_panel.add_child(
		word_label
	)


	# --------------------------------------------------------
	# INSTRUÇÃO
	# --------------------------------------------------------

	instruction_label = Label.new()

	instruction_label.custom_minimum_size = Vector2(
		0,
		48
	)

	instruction_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	instruction_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	instruction_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	instruction_label.add_theme_font_size_override(
		"font_size",
		20
	)

	instruction_label.add_theme_color_override(
		"font_color",
		Color.BLACK
	)

	main_column.add_child(
		instruction_label
	)


	# --------------------------------------------------------
	# OPÇÕES
	# --------------------------------------------------------

	options_column = VBoxContainer.new()

	options_column.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	options_column.add_theme_constant_override(
		"separation",
		8
	)

	main_column.add_child(
		options_column
	)


	btn1 = criar_botao(
		"",
		30
	)

	btn2 = criar_botao(
		"",
		30
	)

	btn3 = criar_botao(
		"",
		30
	)

	for botao in [btn1, btn2, btn3]:

		botao.custom_minimum_size = Vector2(
			0,
			62
		)

		botao.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		options_column.add_child(
			botao
		)

	# Ligações
	btn1.pressed.connect(
		func():
			verificar_resposta(btn1.text)
	)

	btn2.pressed.connect(
		func():
			verificar_resposta(btn2.text)
	)

	btn3.pressed.connect(
		func():
			verificar_resposta(btn3.text)
	)


	# --------------------------------------------------------
	# FINAL
	# --------------------------------------------------------

	final_buttons = VBoxContainer.new()

	final_buttons.add_theme_constant_override(
		"separation",
		8
	)

	final_buttons.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	final_buttons.visible = false

	main_column.add_child(
		final_buttons
	)


	btn_reiniciar = criar_botao(
		"JOGAR DE NOVO",
		26
	)

	btn_reiniciar.custom_minimum_size = Vector2(
		0,
		64
	)

	btn_reiniciar.pressed.connect(
		reiniciar_jogo
	)

	final_buttons.add_child(
		btn_reiniciar
	)


	btn_menu_final = criar_botao(
		"VOLTAR AO MENU",
		24
	)

	btn_menu_final.custom_minimum_size = Vector2(
		0,
		64
	)

	btn_menu_final.pressed.connect(
		voltar_menu
	)

	final_buttons.add_child(
		btn_menu_final
	)


	# --------------------------------------------------------
	# PAINEL DE VOLUME
	# --------------------------------------------------------

	criar_volume()


# ============================================================
# VOLUME
# ============================================================

func criar_volume() -> void:

	volume_panel = PanelContainer.new()

	volume_panel.custom_minimum_size = Vector2(
		280,
		80
	)

	volume_panel.visible = false

	volume_panel.set_anchors_preset(
		Control.PRESET_TOP_RIGHT
	)

	volume_panel.position = Vector2(
		-300,
		85
	)

	estilizar_painel(
		volume_panel,
		Color(
			1,
			1,
			1,
			0.96
		)
	)

	add_child(
		volume_panel
	)


	volume_slider = HSlider.new()

	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = (
		audio.load_saved_volume()
	)

	volume_slider.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	volume_slider.value_changed.connect(
		func(value: float):
			audio.save_master_volume(value)
	)

	volume_panel.add_child(
		volume_slider
	)


# ============================================================
# FASE
# ============================================================

func carregar_fase() -> void:

	respondendo = false

	if fase_atual >= fases.size():

		finalizar_jogo()

		return

	var fase = fases[fase_atual]

	resposta_correta = fase["silaba"]

	word_panel.show()
	animal_panel.show()

	options_column.show()

	final_buttons.hide()

	word_label.text = (
		fase["incompleto"]
	)

	animal_image.texture = load(
		fase["imagem"]
	)

	instruction_label.text = (
		"Escolha a sílaba que completa o nome."
	)

	atualizar_progresso()

	var opcoes = fase["opcoes"].duplicate()

	opcoes.shuffle()

	btn1.text = opcoes[0]
	btn2.text = opcoes[1]
	btn3.text = opcoes[2]

	for botao in [
		btn1,
		btn2,
		btn3
	]:

		botao.disabled = false
		botao.show()

	call_deferred(
		"anunciar_fase"
	)


func anunciar_fase() -> void:

	if fase_atual >= fases.size():
		return

	var fase = fases[fase_atual]

	await audio.speak_and_wait(
		"animal_" + fase["audio"],
		0.4
	)

	await audio.speak_and_wait(
		"instruction_choose_syllable",
		0.6
	)


# ============================================================
# RESPOSTA
# ============================================================

func verificar_resposta(
	resposta: String
) -> void:

	if respondendo:
		return

	respondendo = true

	var fase = fases[fase_atual]

	for botao in [
		btn1,
		btn2,
		btn3
	]:

		botao.disabled = true

	audio.stop_voice()

	audio.play_voice(
		"syllable_" + resposta.to_lower()
	)

	if resposta == resposta_correta:

		word_label.text = (
			fase["animal"]
		)

		instruction_label.text = (
			"Muito bem!"
		)

		estilizar_painel(
			word_panel,
			Color(
				0.65,
				1.0,
				0.55
			)
		)

		await audio.speak_and_wait(
			"feedback_correct",
			0.6
		)

		await get_tree().create_timer(
			0.8
		).timeout

		estilizar_painel(
			word_panel,
			Color.WHITE
		)

		fase_atual += 1

		carregar_fase()

	else:

		instruction_label.text = (
			"Tente outra vez."
		)

		estilizar_painel(
			word_panel,
			Color(
				1.0,
				0.65,
				0.65
			)
		)

		await audio.speak_and_wait(
			"feedback_try_again",
			0.8
		)

		await get_tree().create_timer(
			0.4
		).timeout

		estilizar_painel(
			word_panel,
			Color.WHITE
		)

		carregar_fase()


# ============================================================
# PROGRESSO
# ============================================================

func atualizar_progresso() -> void:

	var texto := ""

	for i in range(fases.size()):

		if i < fase_atual:
			texto += "●"
		else:
			texto += "○"

		if i < fases.size() - 1:
			texto += "   "

	progress_label.text = texto


# ============================================================
# FINAL
# ============================================================

func finalizar_jogo() -> void:

	progress_label.text = (
		"●   ●   ●   ●   ●   ●   ●"
	)

	word_label.text = (
		"PARABÉNS!"
	)

	instruction_label.text = (
		"Você completou o Zoológico das Sílabas!"
	)

	animal_panel.hide()

	options_column.hide()

	final_buttons.show()

	estilizar_painel(
		word_panel,
		Color(
			0.72,
			1.0,
			0.62
		)
	)

	criar_confetes()

	audio.play_voice(
		"final_congratulations"
	)


func reiniciar_jogo() -> void:

	fase_atual = 0

	estilizar_painel(
		word_panel,
		Color.WHITE
	)

	carregar_fase()


# ============================================================
# BOTÕES
# ============================================================

func repetir_instrucao() -> void:

	if fase_atual >= fases.size():

		audio.play_voice(
			"final_congratulations"
		)

		return

	anunciar_fase()


func abrir_tutorial() -> void:

	audio.stop_voice()

	get_tree().change_scene_to_file(
		"res://scenes/Tutorial.tscn"
	)


func voltar_menu() -> void:

	audio.stop_voice()

	get_tree().change_scene_to_file(
		"res://scenes/Menu.tscn"
	)


func toggle_volume_panel() -> void:

	volume_panel.visible = (
		not volume_panel.visible
	)


# ============================================================
# CONFETES
# ============================================================

func criar_confetes() -> void:

	var tela := get_viewport_rect().size

	for i in range(32):

		var confete := ColorRect.new()

		confete.size = Vector2(
			randf_range(8.0, 18.0),
			randf_range(8.0, 18.0)
		)

		confete.color = Color.from_hsv(
			randf(),
			0.75,
			1.0
		)

		confete.position = Vector2(
			randf_range(
				0.0,
				tela.x
			),
			randf_range(
				-200.0,
				-20.0
			)
		)

		confete.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		add_child(confete)

		var tween := create_tween()

		tween.tween_property(
			confete,
			"position:y",
			tela.y + 40.0,
			randf_range(
				2.2,
				4.2
			)
		)

		tween.tween_callback(
			confete.queue_free
		)


# ============================================================
# ESTILO
# ============================================================

func criar_botao(
	texto: String,
	tamanho_fonte: int
) -> Button:

	var botao := Button.new()

	botao.text = texto

	botao.add_theme_font_size_override(
		"font_size",
		tamanho_fonte
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

	estilizar_botao(
		botao
	)

	return botao


func estilizar_painel(
	painel: Control,
	cor: Color
) -> void:

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = cor

	estilo.border_color = Color.BLACK

	estilo.set_border_width_all(
		4
	)

	estilo.set_corner_radius_all(
		20
	)

	estilo.shadow_color = Color(
		0,
		0,
		0,
		0.30
	)

	estilo.shadow_size = 7

	estilo.shadow_offset = Vector2(
		4,
		4
	)

	painel.add_theme_stylebox_override(
		"panel",
		estilo
	)


func estilizar_botao(
	botao: Button
) -> void:

	var normal := StyleBoxFlat.new()

	normal.bg_color = Color.WHITE

	normal.border_color = Color.BLACK

	normal.set_border_width_all(
		4
	)

	normal.set_corner_radius_all(
		18
	)

	normal.shadow_color = Color(
		0,
		0,
		0,
		0.30
	)

	normal.shadow_size = 6

	normal.shadow_offset = Vector2(
		4,
		4
	)


	var pressed := normal.duplicate()

	pressed.bg_color = Color(
		0.75,
		0.90,
		1.0
	)


	var hover := normal.duplicate()

	hover.bg_color = Color(
		0.88,
		0.95,
		1.0
	)


	botao.add_theme_stylebox_override(
		"normal",
		normal
	)

	botao.add_theme_stylebox_override(
		"pressed",
		pressed
	)

	botao.add_theme_stylebox_override(
		"hover",
		hover
	)
