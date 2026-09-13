extends Control

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const SETTINGS_PATH := "user://zoo_settings.cfg"

var audio: AccessibilityAudio
var word_label: Label
var feedback_label: Label
var option_buttons: Array[Button] = []
var start_button: Button
var sound_button: Button
var completed := false

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	_build_interface()

func _build_interface() -> void:
	var background := TextureRect.new()
	background.texture = load("res://img/fundo_jogo.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.15, 0.10, 0.14)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size.y = 58
	top_bar.add_theme_constant_override("separation", 12)
	root.add_child(top_bar)

	var back_button := _make_button("← MENU", 22, Vector2(140, 54), Color(0.96, 0.98, 0.92))
	back_button.pressed.connect(_back_to_menu)
	top_bar.add_child(back_button)

	var title := Label.new()
	title.text = "COMO JOGAR"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(title)

	sound_button = _make_button("", 20, Vector2(172, 54), Color(0.96, 0.98, 0.92))
	sound_button.pressed.connect(_toggle_sound)
	top_bar.add_child(sound_button)
	_update_sound_button()

	var skip_button := _make_button("PULAR", 20, Vector2(120, 54), Color(1.0, 0.92, 0.72))
	skip_button.pressed.connect(_start_game)
	top_bar.add_child(skip_button)

	var tutorial_card := PanelContainer.new()
	tutorial_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_card.add_theme_stylebox_override("panel", _panel_style(Color(1, 1, 1, 0.96), 28, 0))
	root.add_child(tutorial_card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 36)
	card_margin.add_theme_constant_override("margin_top", 30)
	card_margin.add_theme_constant_override("margin_right", 36)
	card_margin.add_theme_constant_override("margin_bottom", 30)
	tutorial_card.add_child(card_margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	card_margin.add_child(columns)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.9
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)

	var look_label := Label.new()
	look_label.text = "1. OLHE O ANIMAL"
	look_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	look_label.add_theme_font_size_override("font_size", 26)
	look_label.add_theme_color_override("font_color", Color(0.08, 0.30, 0.18))
	left.add_child(look_label)

	var animal_panel := PanelContainer.new()
	animal_panel.custom_minimum_size = Vector2(390, 390)
	animal_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.88, 0.97, 0.84), 28, 4))
	left.add_child(animal_panel)

	var animal_image := TextureRect.new()
	animal_image.texture = load("res://img/cachorro.png")
	animal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animal_image.custom_minimum_size = Vector2(360, 360)
	animal_panel.add_child(animal_image)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.15
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 18)
	columns.add_child(right)

	var instruction := Label.new()
	instruction.text = "2. COMPLETE O NOME"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 26)
	instruction.add_theme_color_override("font_color", Color(0.08, 0.30, 0.18))
	right.add_child(instruction)

	var explanation := Label.new()
	explanation.text = "Uma sílaba está faltando. Escolha abaixo qual completa a palavra."
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 23)
	explanation.add_theme_color_override("font_color", Color(0.16, 0.20, 0.18))
	right.add_child(explanation)

	var word_panel := PanelContainer.new()
	word_panel.custom_minimum_size = Vector2(520, 112)
	word_panel.add_theme_stylebox_override("panel", _panel_style(Color.WHITE, 24, 4))
	right.add_child(word_panel)

	word_label = Label.new()
	word_label.text = "__CHORRO"
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.add_theme_font_size_override("font_size", 52)
	word_label.add_theme_color_override("font_color", Color(0.08, 0.14, 0.10))
	word_panel.add_child(word_label)

	var options := HBoxContainer.new()
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 16)
	right.add_child(options)

	for syllable in ["CA", "BA", "PA"]:
		var button := _make_button(syllable, 42, Vector2(150, 92), Color(0.82, 0.94, 1.0))
		button.pressed.connect(_on_option_pressed.bind(button, syllable))
		option_buttons.append(button)
		options.add_child(button)

	feedback_label = Label.new()
	feedback_label.text = "3. TENTE: qual sílaba começa CACHORRO?"
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size.y = 60
	feedback_label.add_theme_font_size_override("font_size", 24)
	feedback_label.add_theme_color_override("font_color", Color(0.20, 0.24, 0.20))
	right.add_child(feedback_label)

	start_button = _make_button("COMEÇAR O JOGO", 30, Vector2(360, 78), Color(0.55, 0.90, 0.48))
	start_button.visible = false
	start_button.pressed.connect(_start_game)
	right.add_child(_center_control(start_button))

	if not option_buttons.is_empty():
		option_buttons[0].grab_focus()

func _on_option_pressed(button: Button, syllable: String) -> void:
	if completed:
		return

	audio.play_syllable(syllable)

	if syllable == "CA":
		completed = true
		word_label.text = "CACHORRO"
		feedback_label.text = "MUITO BEM! CACHORRO começa com CA."
		feedback_label.add_theme_color_override("font_color", Color(0.06, 0.45, 0.18))
		_style_option(button, Color(0.55, 0.90, 0.48))
		for option in option_buttons:
			option.disabled = true
		start_button.visible = true
		start_button.grab_focus()
	else:
		feedback_label.text = "QUASE! Tente outra sílaba."
		feedback_label.add_theme_color_override("font_color", Color(0.72, 0.28, 0.08))
		_style_option(button, Color(1.0, 0.76, 0.68))
		await get_tree().create_timer(0.55).timeout
		if is_instance_valid(button) and not completed:
			_style_option(button, Color(0.82, 0.94, 1.0))

func _start_game() -> void:
	_mark_tutorial_seen()
	get_tree().change_scene_to_file("res://scenes/Jogo.tscn")

func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _mark_tutorial_seen() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("tutorial", "seen", true)
	config.save(SETTINGS_PATH)

func _toggle_sound() -> void:
	audio.toggle_muted()
	_update_sound_button()

func _update_sound_button() -> void:
	sound_button.text = "SOM: OFF" if audio.is_muted() else "SOM: ON"

func _center_control(control: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.add_child(control)
	return center

func _style_option(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.07)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.07)))
	button.add_theme_stylebox_override("disabled", _button_style(color))

func _make_button(text: String, font_size: int, minimum: Vector2, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.06, 0.12, 0.08))
	button.add_theme_color_override("font_hover_color", Color(0.06, 0.12, 0.08))
	button.add_theme_color_override("font_pressed_color", Color(0.06, 0.12, 0.08))
	button.add_theme_color_override("font_focus_color", Color(0.06, 0.12, 0.08))
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.07)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.07)))
	button.add_theme_stylebox_override("focus", _focus_style())
	return button

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.08, 0.18, 0.12)
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style

func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.75, 0.12)
	style.set_border_width_all(6)
	style.set_corner_radius_all(22)
	return style

func _panel_style(color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.08, 0.18, 0.12)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style
