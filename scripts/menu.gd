extends Control

const AccessibilityAudio = preload(
	"res://scripts/accessibility_audio.gd"
)

const SETTINGS_PATH := "user://zoo_settings.cfg"

@onready var btn_jogar: Button = $BtnJogar

var audio

var btn_como_jogar: Button
var btn_volume: Button

var volume_panel: Panel
var volume_slider: HSlider


func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)

	audio.play_music("menu")

	configurar_menu_mobile()

	criar_controles_acessibilidade()

	get_viewport().size_changed.connect(
		configurar_menu_mobile
	)

	btn_jogar.pressed.connect(iniciar_jogo)

	# No mobile não existe hover.
	# A própria ação de toque é a interação principal.
	btn_jogar.pressed.connect(
		func():
			audio.play_voice("menu_play")
	)


func configurar_menu_mobile() -> void:
	var tela := get_viewport_rect().size

	var margem := tela.x * 0.08

	var largura_botao := minf(
		tela.x - margem * 2.0,
		420.0
	)

	var altura_jogar := clampf(
		tela.y * 0.09,
		84.0,
		112.0
	)

	var altura_secundario := clampf(
		tela.y * 0.075,
		68.0,
		92.0
	)

	# -------------------------
	# BOTÃO JOGAR
	# -------------------------

	btn_jogar.size = Vector2(
		largura_botao,
		altura_jogar
	)

	btn_jogar.position = Vector2(
		(tela.x - largura_botao) / 2.0,
		tela.y * 0.59
	)

	estilizar_botao(
		btn_jogar,
		clampf(
			tela.x * 0.075,
			34.0,
			52.0
		)
	)

	# -------------------------
	# COMO JOGAR
	# -------------------------

	if btn_como_jogar != null:
		btn_como_jogar.size = Vector2(
			largura_botao,
			altura_secundario
		)

		btn_como_jogar.position = Vector2(
			(tela.x - largura_botao) / 2.0,
			tela.y * 0.72
		)

		estilizar_botao(
			btn_como_jogar,
			clampf(
				tela.x * 0.045,
				24.0,
				34.0
			)
		)

	# -------------------------
	# BOTÃO SOM
	# -------------------------

	if btn_volume != null:
		var tamanho_som := clampf(
			tela.x * 0.16,
			64.0,
			84.0
		)

		btn_volume.size = Vector2(
			tamanho_som,
			tamanho_som
		)

		btn_volume.position = Vector2(
			tela.x - tamanho_som - 20.0,
			20.0
		)

		estilizar_botao(
			btn_volume,
			26.0
		)

	# -------------------------
	# PAINEL DE VOLUME
	# -------------------------

	if volume_panel != null:
		var painel_largura := minf(
			tela.x - 40.0,
			330.0
		)

		volume_panel.size = Vector2(
			painel_largura,
			96.0
		)

		volume_panel.position = Vector2(
			tela.x - painel_largura - 20.0,
			100.0
		)

		if volume_slider != null:
			volume_slider.size = Vector2(
				painel_largura - 40.0,
				44.0
			)

			volume_slider.position = Vector2(
				20.0,
				26.0
			)


func iniciar_jogo() -> void:
	audio.stop_voice()

	if tutorial_ja_visto():
		get_tree().change_scene_to_file(
			"res://scenes/Jogo.tscn"
		)
	else:
		get_tree().change_scene_to_file(
			"res://scenes/Tutorial.tscn"
		)


func abrir_tutorial() -> void:
	audio.stop_voice()

	get_tree().change_scene_to_file(
		"res://scenes/Tutorial.tscn"
	)


func criar_controles_acessibilidade() -> void:
	var tela := get_viewport_rect().size

	# -------------------------
	# COMO JOGAR
	# -------------------------

	btn_como_jogar = Button.new()
	btn_como_jogar.text = "COMO JOGAR"

	estilizar_botao(
		btn_como_jogar,
		30.0
	)

	btn_como_jogar.pressed.connect(
		abrir_tutorial
	)

	btn_como_jogar.pressed.connect(
		func():
			audio.play_voice("menu_how_to_play")
	)

	add_child(btn_como_jogar)

	# -------------------------
	# VOLUME
	# -------------------------

	btn_volume = Button.new()
	btn_volume.text = "🔊"

	estilizar_botao(
		btn_volume,
		28.0
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
	volume_slider.value = audio.load_saved_volume()

	volume_slider.value_changed.connect(
		func(value: float):
			audio.save_master_volume(value)
	)

	volume_panel.add_child(volume_slider)

	# Faz o primeiro posicionamento imediatamente.
	configurar_menu_mobile()


func toggle_volume_panel() -> void:
	volume_panel.visible = not volume_panel.visible


func tutorial_ja_visto() -> bool:
	var config := ConfigFile.new()

	if config.load(SETTINGS_PATH) != OK:
		return false

	return bool(
		config.get_value(
			"tutorial",
			"seen",
			false
		)
	)


func estilizar_botao(
	botao: Button,
	tamanho_fonte: float = 42.0
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

	botao.add_theme_color_override(
		"font_hover_color",
		Color.BLACK
	)

	var normal := StyleBoxFlat.new()

	normal.bg_color = Color.WHITE
	normal.border_color = Color.BLACK

	normal.set_border_width_all(5)
	normal.set_corner_radius_all(24)

	normal.shadow_color = Color(
		0,
		0,
		0,
		0.35
	)

	normal.shadow_size = 8
	normal.shadow_offset = Vector2(5, 5)

	var pressed := normal.duplicate()

	pressed.bg_color = Color(
		0.75,
		0.90,
		1.0
	)

	var hover := normal.duplicate()

	hover.bg_color = Color(
		0.85,
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


func estilizar_painel(
	painel: Panel,
	cor: Color
) -> void:

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = cor
	estilo.border_color = Color.BLACK

	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(18)

	estilo.shadow_color = Color(
		0,
		0,
		0,
		0.25
	)

	estilo.shadow_size = 6

	painel.add_theme_stylebox_override(
		"panel",
		estilo
	)
