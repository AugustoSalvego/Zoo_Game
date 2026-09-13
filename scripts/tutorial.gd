extends Control

signal tutorial_correct_choice

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const SETTINGS_PATH := "user://zoo_settings.cfg"
const VOLUME_ICON := preload("res://audio/icons/volume.png")
const MUTED_ICON := preload("res://audio/icons/muted.png")

var audio: AccessibilityAudio
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
var pointer: Control

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	criar_interface()
	await get_tree().process_frame
	executar_tutorial()

func criar_interface() -> void:
	fundo = TextureRect.new()
	fundo.texture = load("res://img/fundo_jogo.png")
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	instruction_panel = Panel.new()
	instruction_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	instruction_panel.offset_left = -450
	instruction_panel.offset_top = 24
	instruction_panel.offset_right = 450
	instruction_panel.offset_bottom = 120
	estilizar_painel(instruction_panel, Color(1, 1, 1, 0.96))
	add_child(instruction_panel)

	instruction_label = Label.new()
	instruction_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 34)
	instruction_label.add_theme_color_override("font_color", Color.BLACK)
	instruction_panel.add_child(instruction_label)

	animal_panel = Panel.new()
	animal_panel.set_anchors_preset(Control.PRESET_CENTER)
	animal_panel.offset_left = -210
	animal_panel.offset_top = -390
	animal_panel.offset_right = 210
	animal_panel.offset_bottom = 30
	animal_panel.clip_contents = true
	estilizar_painel(animal_panel, Color(0.82, 0.95, 0.82))
	add_child(animal_panel)

	animal_image = TextureRect.new()
	animal_image.texture = load("res://img/cachorro.png")
	animal_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	animal_image.offset_left = 18
	animal_image.offset_top = 18
	animal_image.offset_right = -18
	animal_image.offset_bottom = -18
	animal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animal_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animal_panel.add_child(animal_image)

	word_panel = Panel.new()
	word_panel.set_anchors_preset(Control.PRESET_CENTER)
	word_panel.offset_left = -300
	word_panel.offset_top = 70
	word_panel.offset_right = 300
	word_panel.offset_bottom = 200
	estilizar_painel(word_panel, Color.WHITE)
	add_child(word_panel)

	word_label = Label.new()
	word_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	word_label.text = "__CHORRO"
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.add_theme_font_size_override("font_size", 62)
	word_label.add_theme_color_override("font_color", Color.BLACK)
	word_panel.add_child(word_label)

	btn_ca = criar_opcao("CA", -415)
	btn_ba = criar_opcao("BA", 0)
	btn_pa = criar_opcao("PA", 415)

	btn_ca.pressed.connect(func(): verificar_tutorial("CA"))
	btn_ba.pressed.connect(func(): verificar_tutorial("BA"))
	btn_pa.pressed.connect(func(): verificar_tutorial("PA"))
	btn_ca.mouse_entered.connect(_on_ca_hovered)
	btn_ba.mouse_entered.connect(_on_ba_hovered)
	btn_pa.mouse_entered.connect(_on_pa_hovered)

	btn_skip = Button.new()
	btn_skip.text = "PULAR"
	btn_skip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_skip.offset_left = 24
	btn_skip.offset_top = 24
	btn_skip.offset_right = 174
	btn_skip.offset_bottom = 94
	estilizar_botao_pequeno(btn_skip)
	btn_skip.pressed.connect(finalizar_tutorial)
	btn_skip.mouse_entered.connect(func(): audio.play_voice("ui_skip"))
	add_child(btn_skip)

	btn_repeat = Button.new()
	btn_repeat.text = "🔊"
	btn_repeat.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_repeat.offset_left = -220
	btn_repeat.offset_top = 24
	btn_repeat.offset_right = -130
	btn_repeat.offset_bottom = 94
	estilizar_botao_pequeno(btn_repeat)
	btn_repeat.pressed.connect(repetir_instrucao)
	add_child(btn_repeat)

	btn_volume = Button.new()
	btn_volume.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_volume.offset_left = -118
	btn_volume.offset_top = 24
	btn_volume.offset_right = -28
	btn_volume.offset_bottom = 94
	btn_volume.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estilizar_botao_pequeno(btn_volume)
	atualizar_icone_volume()
	btn_volume.pressed.connect(toggle_volume_panel)
	btn_volume.mouse_entered.connect(func(): audio.play_voice("ui_volume"))
	add_child(btn_volume)

	volume_panel = Panel.new()
	volume_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	volume_panel.offset_left = -330
	volume_panel.offset_top = 108
	volume_panel.offset_right = -28
	volume_panel.offset_bottom = 198
	volume_panel.visible = false
	estilizar_painel(volume_panel, Color(1, 1, 1, 0.97))
	add_child(volume_panel)

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

	pointer = criar_seta_indicadora()
	pointer.visible = false
	add_child(pointer)

func _on_ca_hovered() -> void:
	if not btn_ca.disabled:
		audio.play_syllable("CA")

func _on_ba_hovered() -> void:
	if not btn_ba.disabled:
		audio.play_syllable("BA")

func _on_pa_hovered() -> void:
	if not btn_pa.disabled:
		audio.play_syllable("PA")

func executar_tutorial() -> void:
	bloquear_opcoes(true)
	await falar_e_mostrar("tutorial_welcome", "Vamos aprender a jogar!", 2.2)
	if not tutorial_ativo: return

	destacar(animal_panel, Color(1.0, 0.95, 0.55))
	await falar_e_mostrar("tutorial_look_animal", "Olhe o animal.", 1.5)
	if not tutorial_ativo: return
	await audio.play_word_and_wait("CACHORRO", 1.1)
	if not tutorial_ativo: return

	destacar(animal_panel, Color(0.82, 0.95, 0.82))
	destacar(word_panel, Color(1.0, 0.95, 0.55))
	await falar_e_mostrar("tutorial_word_missing", "Uma parte da palavra está faltando.", 2.2)
	if not tutorial_ativo: return

	bloquear_opcoes(false)
	destacar_botao(btn_ca)
	posicionar_seta()
	pointer.visible = true
	animar_seta()
	await falar_e_mostrar("tutorial_choose_ca", "Escolha a sílaba CA.", 1.8)
	if not tutorial_ativo: return
	await audio.play_syllable_and_wait("CA", 0.7)
	if not tutorial_ativo: return

	instruction_label.text = "Agora clique em CA."
	current_voice_key = "tutorial_click_ca"
	audio.play_voice(current_voice_key)
	await tutorial_correct_choice
	if not tutorial_ativo: return

	pointer.visible = false
	word_label.text = "CACHORRO"
	destacar(word_panel, Color(0.65, 1.0, 0.55))
	await falar_e_mostrar("feedback_correct", "Muito bem! Você acertou!", 1.8)
	if not tutorial_ativo: return

	await falar_e_mostrar("tutorial_your_turn", "Agora é sua vez!", 1.8)
	if tutorial_ativo:
		finalizar_tutorial()

func verificar_tutorial(resposta: String) -> void:
	if not tutorial_ativo:
		return
	audio.stop_voice()
	await audio.play_syllable_and_wait(resposta, 0.65)
	if resposta == "CA":
		bloquear_opcoes(true)
		pointer.visible = false
		tutorial_correct_choice.emit()
	else:
		instruction_label.text = "Tente outra vez. Procure CA."
		current_voice_key = "feedback_try_again"
		await audio.speak_and_wait(current_voice_key, 1.2)
		if tutorial_ativo:
			destacar_botao(btn_ca)
			posicionar_seta()
			pointer.visible = true

func repetir_instrucao() -> void:
	if current_voice_key.begins_with("syllable_"):
		audio.play_syllable(current_voice_key.trim_prefix("syllable_").to_upper())
	else:
		audio.play_voice(current_voice_key)

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

func criar_opcao(texto: String, deslocamento_x: float) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.set_anchors_preset(Control.PRESET_CENTER)
	botao.offset_left = deslocamento_x - 115
	botao.offset_top = 285
	botao.offset_right = deslocamento_x + 115
	botao.offset_bottom = 405
	estilizar_botao(botao)
	add_child(botao)
	return botao

func bloquear_opcoes(bloquear: bool) -> void:
	for botao in [btn_ca, btn_ba, btn_pa]:
		botao.disabled = bloquear

func destacar(painel: Panel, cor: Color) -> void:
	estilizar_painel(painel, cor)

func destacar_botao(botao: Button) -> void:
	aplicar_estado_botao(botao, Color(1.0, 0.95, 0.45))

func aplicar_estado_botao(botao: Button, cor: Color) -> void:
	var normal := criar_estilo_botao(cor)
	var hover := criar_estilo_botao(cor.lightened(0.06))
	var pressed := criar_estilo_botao(cor.darkened(0.06))
	var disabled := normal.duplicate()
	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", pressed)
	botao.add_theme_stylebox_override("disabled", disabled)

func criar_seta_indicadora() -> Control:
	var holder := Control.new()
	holder.size = Vector2(54, 66)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var seta := Polygon2D.new()
	seta.polygon = PackedVector2Array([
		Vector2(21, 0), Vector2(33, 0), Vector2(33, 35),
		Vector2(49, 35), Vector2(27, 62), Vector2(5, 35), Vector2(21, 35)
	])
	seta.color = Color(1.0, 0.78, 0.10)
	holder.add_child(seta)
	return holder

func posicionar_seta() -> void:
	if pointer == null or btn_ca == null:
		return
	pointer.position = btn_ca.position + Vector2((btn_ca.size.x - pointer.size.x) / 2.0, -78)

func animar_seta() -> void:
	if pointer == null:
		return
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pointer, "position:y", pointer.position.y + 10.0, 0.45)
	tween.tween_property(pointer, "position:y", pointer.position.y, 0.45)

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
	estilo.set_corner_radius_all(24)
	estilo.shadow_color = Color(0, 0, 0, 0.30)
	estilo.shadow_size = 8
	estilo.shadow_offset = Vector2(5, 5)
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
	botao.add_theme_font_size_override("font_size", 26)
	botao.add_theme_constant_override("icon_max_width", 48)

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
