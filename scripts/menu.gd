extends Control

const SETTINGS_PATH := "user://zoo_settings.cfg"
const VOLUME_ICON := preload("res://audio/icons/volume.png")
const MUTED_ICON := preload("res://audio/icons/muted.png")

@onready var btn_jogar: Button = $BtnJogar

var audio: AccessibilityAudio
var btn_como_jogar: Button
var btn_volume: Button
var volume_panel: Panel
var volume_slider: HSlider
var navegando := false


func _ready() -> void:
	audio = Audio
	configurar_botoes_principais()
	criar_controles_audio()

	# The title is baked into the original background. It is narrated only once
	# the complete Marin pack exists, avoiding a temporary system-TTS voice.
	if audio.is_marin_ready():
		call_deferred("_anunciar_titulo")


func _anunciar_titulo() -> void:
	await get_tree().create_timer(0.18).timeout
	if not navegando:
		audio.play_voice("menu_title")


func configurar_botoes_principais() -> void:
	btn_jogar.text = audio.get_display_text("menu_play", "JOGAR")
	btn_jogar.set_anchors_preset(Control.PRESET_CENTER)
	btn_jogar.offset_left = -190
	btn_jogar.offset_top = 110
	btn_jogar.offset_right = 190
	btn_jogar.offset_bottom = 230
	estilizar_botao(btn_jogar, 46)
	conectar_animacao(btn_jogar)
	btn_jogar.pressed.connect(iniciar_jogo)

	btn_como_jogar = Button.new()
	btn_como_jogar.text = audio.get_display_text("menu_how_to_play", "COMO JOGAR")
	btn_como_jogar.set_anchors_preset(Control.PRESET_CENTER)
	btn_como_jogar.offset_left = -190
	btn_como_jogar.offset_top = 260
	btn_como_jogar.offset_right = 190
	btn_como_jogar.offset_bottom = 380
	estilizar_botao(btn_como_jogar, 46)
	conectar_animacao(btn_como_jogar)
	btn_como_jogar.pressed.connect(abrir_tutorial)
	add_child(btn_como_jogar)


func criar_controles_audio() -> void:
	btn_volume = Button.new()
	btn_volume.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_volume.offset_left = -112
	btn_volume.offset_top = 18
	btn_volume.offset_right = -22
	btn_volume.offset_bottom = 90
	btn_volume.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estilizar_botao_pequeno(btn_volume)
	atualizar_icone_volume()
	btn_volume.pressed.connect(toggle_volume_panel)
	add_child(btn_volume)

	volume_panel = Panel.new()
	volume_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	volume_panel.offset_left = -338
	volume_panel.offset_top = 105
	volume_panel.offset_right = -24
	volume_panel.offset_bottom = 205
	volume_panel.visible = false
	estilizar_painel(volume_panel, Color(1, 1, 1, 0.97))
	add_child(volume_panel)

	volume_slider = HSlider.new()
	volume_slider.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	volume_slider.offset_left = 28
	volume_slider.offset_top = 26
	volume_slider.offset_right = -28
	volume_slider.offset_bottom = -26
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = audio.load_saved_volume()
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_panel.add_child(volume_slider)


func iniciar_jogo() -> void:
	if navegando:
		return
	navegando = true
	btn_jogar.disabled = true
	if btn_como_jogar != null:
		btn_como_jogar.disabled = true

	await audio.speak_and_wait("menu_play", 0.55)

	if tutorial_ja_visto():
		get_tree().change_scene_to_file("res://scenes/Jogo.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")


func abrir_tutorial() -> void:
	if navegando:
		return
	navegando = true
	btn_jogar.disabled = true
	if btn_como_jogar != null:
		btn_como_jogar.disabled = true

	await audio.speak_and_wait("menu_how_to_play", 0.75)
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")


func toggle_volume_panel() -> void:
	volume_panel.visible = not volume_panel.visible


func _on_volume_changed(value: float) -> void:
	audio.save_master_volume(value)
	atualizar_icone_volume()


func atualizar_icone_volume() -> void:
	btn_volume.icon = MUTED_ICON if audio.is_muted() else VOLUME_ICON
	btn_volume.tooltip_text = audio.get_display_text("ui_volume", "Volume")


func tutorial_ja_visto() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	return bool(config.get_value("tutorial", "seen", false))


func conectar_animacao(botao: Button) -> void:
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.resized.connect(func(): botao.pivot_offset = botao.size / 2.0)
	botao.mouse_entered.connect(func(): animar_escala(botao, Vector2(1.045, 1.045), 0.12))
	botao.mouse_exited.connect(func(): animar_escala(botao, Vector2.ONE, 0.12))
	botao.button_down.connect(func(): animar_escala(botao, Vector2(0.97, 0.97), 0.07))
	botao.button_up.connect(
		func():
			animar_escala(
				botao,
				Vector2(1.045, 1.045) if botao.is_hovered() else Vector2.ONE,
				0.09
			)
	)
	botao.pivot_offset = botao.size / 2.0


func animar_escala(botao: Control, alvo: Vector2, duracao: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(botao, "scale", alvo, duracao)


func estilizar_botao(botao: Button, tamanho_fonte: int) -> void:
	botao.add_theme_font_size_override("font_size", tamanho_fonte)
	botao.add_theme_color_override("font_color", Color.BLACK)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
	botao.add_theme_color_override("font_focus_color", Color.BLACK)
	botao.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0.68))

	var normal := criar_estilo_botao(Color.WHITE)
	var hover := criar_estilo_botao(Color(0.94, 0.98, 1.0))
	var pressed := criar_estilo_botao(Color(0.86, 0.94, 1.0))
	var disabled := normal.duplicate()

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", pressed)
	botao.add_theme_stylebox_override("disabled", disabled)


func estilizar_botao_pequeno(botao: Button) -> void:
	estilizar_botao(botao, 26)
	botao.add_theme_constant_override("icon_max_width", 52)


func criar_estilo_botao(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(24)
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 8
	estilo.shadow_offset = Vector2(6, 6)
	return estilo


func estilizar_painel(painel: Panel, cor: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(18)
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 6
	estilo.shadow_offset = Vector2(4, 4)
	painel.add_theme_stylebox_override("panel", estilo)
