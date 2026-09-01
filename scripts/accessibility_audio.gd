extends Node

class_name AccessibilityAudio

const SETTINGS_PATH := "user://zoo_settings.cfg"

var music_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var current_music_key := ""

# Mapeamento dos arquivos de áudio
var musicas := {
	"menu": "res://audio/music_menu.mp3",  # Ajuste o caminho dos seus arquivos se necessário
	"game": "res://audio/music_game.mp3"
}

var falas := {
	"menu_play": "res://audio/voice_play.mp3",
	"menu_how_to_play": "res://audio/voice_how_to_play.mp3",
	"ui_volume": "res://audio/voice_volume.mp3",
	"ui_skip": "res://audio/voice_skip.mp3",
	"tutorial_welcome": "res://audio/voice_tutorial_welcome.mp3",
	"tutorial_look_animal": "res://audio/voice_tutorial_look_animal.mp3",
	"animal_cachorro": "res://audio/voice_animal_cachorro.mp3",
	"tutorial_word_missing": "res://audio/voice_word_missing.mp3",
	"tutorial_choose_ca": "res://audio/voice_choose_ca.mp3",
	"tutorial_click_ca": "res://audio/voice_click_ca.mp3",
	"feedback_correct": "res://audio/voice_correct.mp3",
	"feedback_try_again": "res://audio/voice_try_again.mp3",
	"tutorial_your_turn": "res://audio/voice_your_turn.mp3",
	"instruction_choose_syllable": "res://audio/voice_choose_syllable.mp3",
	"final_congratulations": "res://audio/voice_congratulations.mp3"
}


func _ready() -> void:
	# 1. Cria o player de Música
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	# 2. Cria o player de Vozes
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "Master"
	add_child(voice_player)

	# 3. Cria o player de Efeitos Sonoros
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)

	# Aplica o volume salvo
	var vol_salvo := load_saved_volume()
	save_master_volume(vol_salvo)


func play_music(key: String) -> void:
	if current_music_key == key and music_player.playing:
		return

	if musicas.has(key):
		var caminho: String = musicas[key]
		if ResourceLoader.exists(caminho):
			var stream = load(caminho)
			if stream:
				# Tenta habilitar o loop no recurso se for um arquivo MP3 ou OGG
				if "loop" in stream:
					stream.loop = true
				
				music_player.stream = stream
				music_player.play()
				current_music_key = key
		else:
			push_warning("Arquivo de música não encontrado: " + caminho)


func stop_music() -> void:
	music_player.stop()
	current_music_key = ""


func play_voice(key: String) -> void:
	if falas.has(key):
		var caminho: String = falas[key]
		if ResourceLoader.exists(caminho):
			voice_player.stream = load(caminho)
			voice_player.play()


func speak_and_wait(key: String, fallback_duration: float = 1.5) -> void:
	play_voice(key)
	if voice_player.stream != null and voice_player.playing:
		await voice_player.finished
	else:
		await get_tree().create_timer(fallback_duration).timeout


func stop_voice() -> void:
	voice_player.stop()


func save_master_volume(val: float) -> void:
	var db := linear_to_db(clampf(val, 0.0001, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), val <= 0.01)

	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "volume", val)
	config.save(SETTINGS_PATH)


func load_saved_volume() -> float:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		return config.get_value("audio", "volume", 0.8)
	return 0.8
