extends Control

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const GameData = preload("res://scripts/game_data.gd")

@onready var progress_label: Label = $Margin/Root/TopBar/Progress
@onready var animal_image: TextureRect = $Margin/Root/GameContent/AnimalCard/AnimalMargin/AnimalBox/ImageFrame/AnimalImage
@onready var word_label: Label = $Margin/Root/GameContent/ChallengeCard/ChallengeMargin/Challenge/WordPanel/Word
@onready var feedback_label: Label = $Margin/Root/GameContent/ChallengeCard/ChallengeMargin/Challenge/Feedback
@onready var btn1: Button = $Margin/Root/GameContent/ChallengeCard/ChallengeMargin/Challenge/Options/Btn1
@onready var btn2: Button = $Margin/Root/GameContent/ChallengeCard/ChallengeMargin/Challenge/Options/Btn2
@onready var btn3: Button = $Margin/Root/GameContent/ChallengeCard/ChallengeMargin/Challenge/Options/Btn3
@onready var next_button: Button = $Margin/Root/GameContent/ChallengeCard/ChallengeMargin/Challenge/NextCenter/Next
@onready var menu_button: Button = $Margin/Root/TopBar/Menu
@onready var help_button: Button = $Margin/Root/TopBar/Help
@onready var sound_button: Button = $Margin/Root/TopBar/Sound
@onready var game_content: HBoxContainer = $Margin/Root/GameContent
@onready var finish_content: CenterContainer = $Margin/Root/FinishContent
@onready var finish_label: Label = $Margin/Root/FinishContent/FinishCard/FinishMargin/FinishBox/FinishText
@onready var restart_button: Button = $Margin/Root/FinishContent/FinishCard/FinishMargin/FinishBox/Restart
@onready var final_menu_button: Button = $Margin/Root/FinishContent/FinishCard/FinishMargin/FinishBox/FinalMenu
@onready var help_dialog: AcceptDialog = $HelpDialog

var audio: AccessibilityAudio
var session: Array[Dictionary] = []
var current_question: Dictionary = {}
var option_buttons: Array[Button] = []
var current_index := 0
var attempts := 0
var input_locked := false

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	option_buttons = [btn1, btn2, btn3]
	_connect_signals()
	_style_interface()
	_configure_help()
	session = GameData.build_session()
	_load_question()

func _connect_signals() -> void:
	menu_button.pressed.connect(_back_to_menu)
	help_button.pressed.connect(_show_help)
	sound_button.pressed.connect(_toggle_sound)
	next_button.pressed.connect(_next_question)
	restart_button.pressed.connect(_restart_game)
	final_menu_button.pressed.connect(_back_to_menu)
	for index in range(option_buttons.size()):
		option_buttons[index].pressed.connect(_on_option_pressed.bind(index))

func _style_interface() -> void:
	_style_panel($Margin/Root/GameContent/AnimalCard, Color(0.91, 0.98, 0.88), 28, 0)
	_style_panel($Margin/Root/GameContent/AnimalCard/AnimalMargin/AnimalBox/ImageFrame, Color.WHITE, 26, 4)
	_style_panel($Margin/Root/GameContent/ChallengeCard, Color(1, 1, 1, 0.97), 28, 0)
	_style_panel($Margin/Root/GameContent/ChallengeCard/ChallengeMargin/Challenge/WordPanel, Color(0.98, 0.99, 1.0), 24, 4)
	_style_panel($Margin/Root/FinishContent/FinishCard, Color(1, 1, 1, 0.97), 32, 0)

	_style_button(menu_button, Color(0.96, 0.98, 0.92), 20)
	_style_button(help_button, Color(0.86, 0.94, 1.0), 20)
	_style_button(sound_button, Color(0.96, 0.98, 0.92), 20)
	_style_button(next_button, Color(0.55, 0.90, 0.48), 28)
	_style_button(restart_button, Color(0.55, 0.90, 0.48), 30)
	_style_button(final_menu_button, Color(0.86, 0.94, 1.0), 24)
	for button in option_buttons:
		_style_button(button, Color(0.82, 0.94, 1.0), 42)

	_update_sound_button()

func _configure_help() -> void:
	help_dialog.title = "Como jogar"
	help_dialog.dialog_text = "1. Observe o animal.\n2. Veja qual parte do nome está faltando.\n3. Escolha uma das três sílabas.\n\nSe errar, tente novamente. Depois de duas tentativas, o jogo mostra uma dica.\n\nTeclado: 1, 2 e 3 respondem; Enter avança depois do acerto."
	help_dialog.ok_button_text = "ENTENDI"

func _load_question() -> void:
	if current_index >= session.size():
		_finish_game()
		return

	input_locked = false
	attempts = 0
	current_question = session[current_index]
	animal_image.texture = load(str(current_question.get("imagem", "")))
	word_label.text = str(current_question.get("complemento_silaba", ""))
	feedback_label.text = "Toque em uma sílaba para responder."
	feedback_label.add_theme_color_override("font_color", Color(0.22, 0.26, 0.22))
	next_button.hide()

	var options: Array = current_question.get("opcoes", []).duplicate()
	options.shuffle()
	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		button.text = str(options[index])
		button.disabled = false
		_style_option(button, Color(0.82, 0.94, 1.0))

	_update_progress()
	btn1.grab_focus()

func _on_option_pressed(index: int) -> void:
	if input_locked or index < 0 or index >= option_buttons.size():
		return

	var button := option_buttons[index]
	var selected := button.text
	var correct := str(current_question.get("silaba", ""))
	input_locked = true
	attempts += 1
	audio.play_syllable(selected)

	if selected == correct:
		word_label.text = str(current_question.get("palavra", ""))
		feedback_label.text = "MUITO BEM! Você completou a palavra."
		feedback_label.add_theme_color_override("font_color", Color(0.06, 0.45, 0.18))
		_style_option(button, Color(0.55, 0.90, 0.48))
		for option in option_buttons:
			option.disabled = true
		next_button.show()
		next_button.grab_focus()
		return

	feedback_label.text = "QUASE! Tente outra sílaba."
	feedback_label.add_theme_color_override("font_color", Color(0.72, 0.28, 0.08))
	_style_option(button, Color(1.0, 0.76, 0.68))
	await get_tree().create_timer(0.55).timeout
	if not is_instance_valid(button):
		return
	_style_option(button, Color(0.82, 0.94, 1.0))
	if attempts >= 2:
		_highlight_correct_option()
		feedback_label.text = "DICA: a opção destacada começa o nome deste animal."
		feedback_label.add_theme_color_override("font_color", Color(0.48, 0.34, 0.04))
	input_locked = false

func _highlight_correct_option() -> void:
	var correct := str(current_question.get("silaba", ""))
	for button in option_buttons:
		if button.text == correct:
			_style_option(button, Color(1.0, 0.91, 0.48))
			return

func _next_question() -> void:
	current_index += 1
	_load_question()

func _finish_game() -> void:
	game_content.hide()
	finish_content.show()
	progress_label.text = "COMPLETO!"
	finish_label.text = "Você ajudou a completar o nome de %d animais!" % session.size()
	restart_button.grab_focus()

func _restart_game() -> void:
	session = GameData.build_session()
	current_index = 0
	game_content.show()
	finish_content.hide()
	_load_question()

func _update_progress() -> void:
	var markers := ""
	for i in range(session.size()):
		markers += "●" if i < current_index else "○"
		if i < session.size() - 1:
			markers += " "
	progress_label.text = "ANIMAL %d DE %d   %s" % [current_index + 1, session.size(), markers]

func _toggle_sound() -> void:
	audio.toggle_muted()
	_update_sound_button()

func _update_sound_button() -> void:
	sound_button.text = "SOM: OFF" if audio.is_muted() else "SOM: ON"

func _show_help() -> void:
	help_dialog.popup_centered(Vector2i(680, 420))

func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_1:
		_on_option_pressed(0)
	elif key_event.keycode == KEY_2:
		_on_option_pressed(1)
	elif key_event.keycode == KEY_3:
		_on_option_pressed(2)
	elif key_event.keycode == KEY_ENTER and next_button.visible:
		_next_question()

func _style_option(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_box(color))
	button.add_theme_stylebox_override("hover", _button_box(color.lightened(0.07)))
	button.add_theme_stylebox_override("pressed", _button_box(color.darkened(0.07)))
	button.add_theme_stylebox_override("disabled", _button_box(color))

func _style_button(button: Button, color: Color, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	for theme_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(theme_color, Color(0.06, 0.12, 0.08))
	_style_option(button, color)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color(1.0, 0.75, 0.12)
	focus.set_border_width_all(6)
	focus.set_corner_radius_all(22)
	button.add_theme_stylebox_override("focus", focus)

func _button_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.08, 0.18, 0.12)
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style

func _style_panel(panel: PanelContainer, color: Color, radius: int, border: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.08, 0.18, 0.12)
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)
