extends Control

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const SETTINGS_PATH := "user://zoo_settings.cfg"

var audio: AccessibilityAudio
var sound_button: Button

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	_build_interface()

func _build_interface() -> void:
	var background := TextureRect.new()
	background.texture = load("res://img/fundo_menu.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.12, 0.10, 0.22)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 32)
	root_margin.add_theme_constant_override("margin_top", 28)
	root_margin.add_theme_constant_override("margin_right", 32)
	root_margin.add_theme_constant_override("margin_bottom", 28)
	add_child(root_margin)

	var outer := VBoxContainer.new()
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 18)
	root_margin.add_child(outer)

	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size.y = 64
	outer.add_child(top_bar)

	var brand := Label.new()
	brand.text = "NINOEDU • ALFABETIZAÇÃO"
	brand.add_theme_font_size_override("font_size", 22)
	brand.add_theme_color_override("font_color", Color.WHITE)
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(brand)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	sound_button = _make_button("", 22, Vector2(180, 58), Color(0.96, 0.98, 0.92))
	sound_button.pressed.connect(_toggle_sound)
	top_bar.add_child(sound_button)
	_update_sound_button()

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 520)
	card.add_theme_stylebox_override("panel", _panel_style(Color(1, 1, 1, 0.96), 32, 0))
	center.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 58)
	card_margin.add_theme_constant_override("margin_top", 42)
	card_margin.add_theme_constant_override("margin_right", 58)
	card_margin.add_theme_constant_override("margin_bottom", 42)
	card.add_child(card_margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	card_margin.add_child(content)

	var title := Label.new()
	title.text = "ZOOLÓGICO\nDAS SÍLABAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color(0.08, 0.28, 0.18))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Observe o animal e escolha a sílaba que completa seu nome."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 27)
	subtitle.add_theme_color_override("font_color", Color(0.16, 0.20, 0.18))
	content.add_child(subtitle)

	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	content.add_child(gap)

	var play_button := _make_button("JOGAR", 42, Vector2(420, 96), Color(0.55, 0.90, 0.48))
	play_button.pressed.connect(_start_game)
	content.add_child(_center_control(play_button))

	var tutorial_button := _make_button("COMO JOGAR", 30, Vector2(360, 76), Color(0.82, 0.94, 1.0))
	tutorial_button.pressed.connect(_open_tutorial)
	content.add_child(_center_control(tutorial_button))

	var footer := Label.new()
	footer.text = "Botões grandes • feedback sem punição • suporte a mouse, toque e teclado"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 18)
	footer.add_theme_color_override("font_color", Color(0.32, 0.38, 0.34))
	content.add_child(footer)

	play_button.grab_focus()

func _start_game() -> void:
	if _tutorial_seen():
		get_tree().change_scene_to_file("res://scenes/Jogo.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")

func _open_tutorial() -> void:
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")

func _toggle_sound() -> void:
	audio.toggle_muted()
	_update_sound_button()

func _update_sound_button() -> void:
	if sound_button == null:
		return
	sound_button.text = "SOM: DESLIGADO" if audio.is_muted() else "🔊  SOM: LIGADO"

func _tutorial_seen() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	return bool(config.get_value("tutorial", "seen", false))

func _center_control(control: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.add_child(control)
	return center

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
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.08)))
	button.add_theme_stylebox_override("focus", _focus_style())
	return button

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.08, 0.18, 0.12)
	style.set_border_width_all(4)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 5)
	return style

func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.78, 0.16)
	style.set_border_width_all(6)
	style.set_corner_radius_all(24)
	return style

func _panel_style(color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.08, 0.18, 0.12)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 10)
	return style
