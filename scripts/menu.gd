extends Control

const AccessibilityAudio = preload("res://scripts/accessibility_audio.gd")
const SETTINGS_PATH := "user://zoo_settings.cfg"

@onready var btn_jogar = $BtnJogar

var audio
var btn_como_jogar: Button
var btn_volume: Button
var volume_panel: Panel
var volume_slider: HSlider

func _ready() -> void:
	audio = AccessibilityAudio.new()
	add_child(audio)
	audio.play_music("menu")

	estilizar_botao(btn_jogar)
	btn_jogar.text = "JOGAR"
	btn_jogar.pressed.connect(iniciar_jogo)
	btn_jogar.mouse_entered.connect(func(): audio.play_hover_voice("menu_play"))

	criar_controles_acessibilidade()

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
	var tela := get_viewport_rect().size

	btn_como_jogar = Button.new()
	btn_como_jogar.text = "COMO JOGAR"
	btn_como_jogar.size = Vector2(380, 100)
	btn_como_jogar.position = Vector2((tela.x - btn_como_jogar.size.x) / 2.0, 825)
	estilizar_botao(btn_como_jogar)
	btn_como_jogar.add_theme_font_size_override("font_size", 34)
	btn_como_jogar.pressed.connect(abrir_tutorial)
	btn_como_jogar.mouse_entered.connect(func(): audio.play_hover_voice("menu_how_to_play"))
	add_child(btn_como_jogar)

	btn_volume = Button.new()
	btn_volume.text = "🔊"
	btn_volume.size = Vector2(92, 72)
	btn_volume.position = Vector2(tela.x - 120, 24)
	estilizar_botao_pequeno(btn_volume)
	btn_volume.pressed.connect(toggle_volume_panel)
	btn_volume.mouse_entered.connect(func(): audio.play_hover_voice("ui_volume"))
	add_child(btn_volume)

	volume_panel = Panel.new()
	volume_panel.size = Vector2(300, 96)
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
	volume_slider.position = Vector2(28, 28)
	volume_slider.value_changed.connect(func(value: float): audio.save_master_volume(value))
	volume_panel.add_child(volume_slider)

func toggle_volume_panel() -> void:
	volume_panel.visible = not volume_panel.visible

func tutorial_ja_visto() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	return bool(config.get_value("tutorial", "seen", false))

func estilizar_botao(botao: Button) -> void:
	botao.add_theme_font_size_override("font_size", 60)
	botao.add_theme_color_override("font_color", Color.BLACK)
	botao.add_theme_color_override("font_hover_color", Color.BLACK)
	botao.add_theme_color_override("font_pressed_color", Color.BLACK)
	botao.add_theme_color_override("font_focus_color", Color.BLACK)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.WHITE
	normal.border_color = Color.BLACK
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(25)
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
	botao.add_theme_font_size_override("font_size", 32)

func estilizar_painel(painel: Panel, cor: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(18)
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 6
	painel.add_theme_stylebox_override("panel", estilo)
