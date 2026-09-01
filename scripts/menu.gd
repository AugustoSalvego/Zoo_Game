extends Control

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const SETTINGS_PATH := "user://zoo_settings.cfg"

@onready var btn_jogar: Button = $BtnJogar
@onready var imagem_fundo: TextureRect = get_node_or_null("TextureRect")

var audio: Node

var btn_como_jogar: Button
var btn_volume: Button

var volume_panel: Panel
var volume_slider: HSlider


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

	audio = AccessibilityAudio.new()
	add_child(audio)
	audio.play_music("menu")

	criar_controles_acessibilidade()

	# Usa call_deferred para garantir que o layout carregou antes de posicionar
	call_deferred("configurar_menu_mobile")
	get_viewport().size_changed.connect(configurar_menu_mobile)

	btn_jogar.pressed.connect(iniciar_jogo)
	btn_jogar.pressed.connect(func(): audio.play_voice("menu_play"))


func configurar_menu_mobile() -> void:
	var tela := get_viewport_rect().size
	if tela.x == 0 or tela.y == 0:
		return

	var fator_escala: float = minf(tela.x / 558.0, tela.y / 992.0)

	# ---------------------------------------------------------
	# 1. FORÇA O ENQUADRAMENTO DA NOVA IMAGEM (bg_menu.jpg)
	# ---------------------------------------------------------
	if imagem_fundo != null:
		imagem_fundo.anchor_left = 0.0
		imagem_fundo.anchor_top = 0.0
		imagem_fundo.anchor_right = 1.0
		imagem_fundo.anchor_bottom = 1.0
		imagem_fundo.offset_left = 0.0
		imagem_fundo.offset_top = 0.0
		imagem_fundo.offset_right = 0.0
		imagem_fundo.offset_bottom = 0.0
		
		imagem_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem_fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# ---------------------------------------------------------
	# 2. BOTÕES ACESSÍVEIS (Ocupam 88% da largura na área da grama)
	# ---------------------------------------------------------
	var largura_botao := tela.x * 0.88
	var altura_jogar := clampf(110.0 * fator_escala, 85.0, 140.0)
	var altura_secundario := clampf(90.0 * fator_escala, 70.0, 115.0)

	# BOTÃO JOGAR
	btn_jogar.custom_minimum_size = Vector2(largura_botao, altura_jogar)
	btn_jogar.size = btn_jogar.custom_minimum_size
	
	# Posição mantida na área do gramado abaixo dos animais
	btn_jogar.position = Vector2(
		(tela.x - largura_botao) / 2.0,
		tela.y * 0.68
	)
	
	var tamanho_fonte_jogar := clampf(52.0 * fator_escala, 36.0, 64.0)
	estilizar_botao(btn_jogar, tamanho_fonte_jogar)

	# BOTÃO COMO JOGAR
	if btn_como_jogar != null:
		btn_como_jogar.custom_minimum_size = Vector2(largura_botao, altura_secundario)
		btn_como_jogar.size = btn_como_jogar.custom_minimum_size
		
		var espaco_entre_botoes := 20.0 * fator_escala
		btn_como_jogar.position = Vector2(
			(tela.x - largura_botao) / 2.0,
			btn_jogar.position.y + altura_jogar + espaco_entre_botoes
		)
		
		var tamanho_fonte_como_jogar := clampf(36.0 * fator_escala, 24.0, 44.0)
		estilizar_botao(btn_como_jogar, tamanho_fonte_como_jogar)

	# ---------------------------------------------------------
	# 3. BOTÃO SOM (SUPERIOR DIREITO)
	# ---------------------------------------------------------
	if btn_volume != null:
		var tamanho_som := clampf(85.0 * fator_escala, 68.0, 100.0)
		btn_volume.custom_minimum_size = Vector2(tamanho_som, tamanho_som)
		btn_volume.size = btn_volume.custom_minimum_size
		
		var margem_topo := 20.0 * fator_escala
		var margem_direita := 20.0 * fator_escala
		
		btn_volume.position = Vector2(
			tela.x - tamanho_som - margem_direita,
			margem_topo
		)
		
		var tamanho_fonte_som := clampf(40.0 * fator_escala, 30.0, 50.0)
		estilizar_botao(btn_volume, tamanho_fonte_som)

		if volume_panel != null:
			var painel_largura := minf(tela.x * 0.85, 360.0)
			var painel_altura := 100.0 * fator_escala
			volume_panel.size = Vector2(painel_largura, painel_altura)
			
			volume_panel.position = Vector2(
				tela.x - painel_largura - margem_direita,
				btn_volume.position.y + tamanho_som + 12.0
			)

			if volume_slider != null:
				volume_slider.size = Vector2(painel_largura - 40.0, 48.0)
				volume_slider.position = Vector2(20.0, (painel_altura - 48.0) / 2.0)


func iniciar_jogo() -> void:
	audio.stop_voice()
	if tutorial_ja_visto():
		get_tree().change_scene_to_file("res://scenes/Jogo.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")


func abrir_tutorial() -> void:
	audio.stop_voice()
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")


func criar_controles_acessibilidade() -> void:
	btn_como_jogar = Button.new()
	btn_como_jogar.text = "COMO JOGAR"
	btn_como_jogar.pressed.connect(abrir_tutorial)
	btn_como_jogar.pressed.connect(func(): audio.play_voice("menu_how_to_play"))
	add_child(btn_como_jogar)

	btn_volume = Button.new()
	btn_volume.text = "🔊"
	btn_volume.pressed.connect(toggle_volume_panel)
	btn_volume.pressed.connect(func(): audio.play_voice("ui_volume"))
	add_child(btn_volume)

	volume_panel = Panel.new()
	volume_panel.visible = false
	estilizar_painel(volume_panel, Color(1, 1, 1, 0.96))
	add_child(volume_panel)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = audio.load_saved_volume()
	volume_slider.value_changed.connect(func(value: float): audio.save_master_volume(value))
	
	volume_panel.add_child(volume_slider)


func toggle_volume_panel() -> void:
	volume_panel.visible = not volume_panel.visible


func tutorial_ja_visto() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	return bool(config.get_value("tutorial", "seen", false))


func estilizar_botao(botao: Button, tamanho_fonte: float = 42.0) -> void:
	botao.add_theme_font_size_override("font_size", int(tamanho_fonte))
	botao.add_theme_color_override("font_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
	botao.add_theme_color_override("font_focus_color", Color.BLACK)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.WHITE
	normal.border_color = Color.BLACK
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(20)
	normal.shadow_color = Color(0, 0, 0, 0.25)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(3, 3)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.75, 0.90, 1.0)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.85, 0.95, 1.0)

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("pressed", pressed)
	botao.add_theme_stylebox_override("hover", hover)


func estilizar_painel(painel: Panel, cor: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(16)
	estilo.shadow_color = Color(0, 0, 0, 0.2)
	estilo.shadow_size = 6

	painel.add_theme_stylebox_override("panel", estilo)
