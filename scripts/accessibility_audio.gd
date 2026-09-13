extends Node
class_name AccessibilityAudio

const SETTINGS_PATH := "user://zoo_settings.cfg"

const NINO_A_BASE := "https://raw.githubusercontent.com/RafaelTomazGraciano/ninoedu/main/assets/Vogal_A/Audios/"
const NINO_O_WORDS_BASE := "https://raw.githubusercontent.com/RafaelTomazGraciano/ninoedu/main/assets/Vogal_O/AudiosPalavras/"
const LIGUE_AUDIO_BASE := "https://raw.githubusercontent.com/RafaelTomazGraciano/ligue-as-silabas/main/assets/audios/"

const REMOTE_VOICES := {
	"menu_play": LIGUE_AUDIO_BASE + "jogar.ogg",
	"menu_how_to_play": LIGUE_AUDIO_BASE + "como_jogar.ogg",
	"ui_volume": LIGUE_AUDIO_BASE + "volume.ogg",
	"ui_back": LIGUE_AUDIO_BASE + "voltar.ogg",
	"ui_help": LIGUE_AUDIO_BASE + "como_jogar.ogg",
	"ui_skip": LIGUE_AUDIO_BASE + "como_jogar/pular_tutorial.ogg",
	"tutorial_welcome": LIGUE_AUDIO_BASE + "como_jogar/vamos_aprender_a_jogar.ogg",
	"feedback_correct": LIGUE_AUDIO_BASE + "como_jogar/voce_acertou.ogg",
	"feedback_try_again": LIGUE_AUDIO_BASE + "como_jogar/tente_outra_vez.ogg",
	"tutorial_your_turn": LIGUE_AUDIO_BASE + "como_jogar/sua_vez.ogg"
}

const FALLBACK_TEXTS := {
	"menu_play": "Jogar.",
	"menu_how_to_play": "Como jogar.",
	"ui_volume": "Volume.",
	"ui_back": "Voltar.",
	"ui_help": "Como jogar.",
	"ui_skip": "Pular tutorial.",
	"ui_repeat": "Ouvir novamente.",
	"tutorial_welcome": "Vamos aprender a jogar!",
	"tutorial_look_animal": "Olhe o animal.",
	"tutorial_word_missing": "Uma parte da palavra está faltando.",
	"tutorial_choose_ca": "Escolha a sílaba CA.",
	"tutorial_click_ca": "Agora clique em CA.",
	"feedback_correct": "Parabéns!",
	"feedback_try_again": "Tente outra vez.",
	"tutorial_your_turn": "Agora é sua vez!",
	"instruction_choose_syllable": "Escolha a sílaba que completa o nome.",
	"final_congratulations": "Parabéns! Você completou o Zoológico das Sílabas."
}

const NINO_WORD_URLS := {
	"GATO": NINO_O_WORDS_BASE + "gato.ogg",
	"MACACO": NINO_O_WORDS_BASE + "macaco.ogg",
	"CAVALO": NINO_O_WORDS_BASE + "cavalo.ogg"
}

static var _stream_cache: Dictionary = {}

var voice_player := AudioStreamPlayer.new()
var syllable_player := AudioStreamPlayer.new()
var sfx_player := AudioStreamPlayer.new()
var _tts_voice := ""
var _last_nonzero_volume := 0.8
var _spoken_generation := 0
var _windows_tts_pid := -1

func _ready() -> void:
	add_child(voice_player)
	add_child(syllable_player)
	add_child(sfx_player)
	_tts_voice = _find_portuguese_voice()
	var saved := load_saved_volume()
	if saved > 0.001:
		_last_nonzero_volume = saved
	set_master_volume(saved)

func set_master_volume(value: float) -> void:
	var safe_value := clampf(value, 0.0, 1.0)
	if safe_value > 0.001:
		_last_nonzero_volume = safe_value
	AudioServer.set_bus_mute(0, safe_value <= 0.001)
	if safe_value > 0.001:
		AudioServer.set_bus_volume_db(0, linear_to_db(safe_value))

func save_master_volume(value: float) -> void:
	var safe_value := clampf(value, 0.0, 1.0)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "master_volume", safe_value)
	config.save(SETTINGS_PATH)
	set_master_volume(safe_value)

func load_saved_volume() -> float:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return 0.8
	return clampf(float(config.get_value("audio", "master_volume", 0.8)), 0.0, 1.0)

func is_muted() -> bool:
	return load_saved_volume() <= 0.001

func play_voice(key: String) -> bool:
	var url := str(REMOTE_VOICES.get(key, ""))
	if not url.is_empty():
		_play_remote_nonblocking("voice:" + key, url, voice_player, key)
		return true
	var text := str(FALLBACK_TEXTS.get(key, ""))
	if not text.is_empty():
		return speak_text(text)
	return false

func speak_and_wait(key: String, fallback_seconds: float = 1.2) -> void:
	var url := str(REMOTE_VOICES.get(key, ""))
	if not url.is_empty():
		var stream := await _fetch_stream("voice:" + key, url)
		if stream != null:
			_stop_spoken_audio()
			voice_player.stream = stream
			voice_player.play()
			await voice_player.finished
			return
	var text := str(FALLBACK_TEXTS.get(key, ""))
	if text.is_empty():
		await get_tree().create_timer(fallback_seconds).timeout
		return
	speak_text(text)
	if OS.get_name() == "Windows" and _windows_tts_pid > 0:
		var elapsed := 0.0
		var limit := maxf(fallback_seconds + 3.0, 5.0)
		while OS.is_process_running(_windows_tts_pid) and elapsed < limit:
			await get_tree().create_timer(0.1).timeout
			elapsed += 0.1
	else:
		await get_tree().create_timer(fallback_seconds).timeout

func play_syllable(syllable: String) -> bool:
	var normalized := syllable.strip_edges().to_lower()
	var url := NINO_A_BASE + normalized + ".ogg"
	_play_remote_nonblocking("syllable:" + normalized, url, syllable_player, "", syllable)
	return true

func play_syllable_and_wait(syllable: String, fallback_seconds: float = 0.7) -> void:
	var normalized := syllable.strip_edges().to_lower()
	var stream := await _fetch_stream("syllable:" + normalized, NINO_A_BASE + normalized + ".ogg")
	if stream != null:
		_stop_spoken_audio()
		syllable_player.stream = stream
		syllable_player.play()
		await syllable_player.finished
		return
	speak_text(syllable)
	await get_tree().create_timer(fallback_seconds).timeout

func play_word(word: String) -> bool:
	var normalized := word.strip_edges().to_upper()
	var url := str(NINO_WORD_URLS.get(normalized, ""))
	if not url.is_empty():
		_play_remote_nonblocking("word:" + normalized, url, voice_player, "", word.capitalize())
		return true
	return speak_text(word.capitalize())

func play_word_and_wait(word: String, fallback_seconds: float = 1.0) -> void:
	var normalized := word.strip_edges().to_upper()
	var url := str(NINO_WORD_URLS.get(normalized, ""))
	if not url.is_empty():
		var stream := await _fetch_stream("word:" + normalized, url)
		if stream != null:
			_stop_spoken_audio()
			voice_player.stream = stream
			voice_player.play()
			await voice_player.finished
			return
	speak_text(word.capitalize())
	await get_tree().create_timer(fallback_seconds).timeout

func speak_text(text: String) -> bool:
	_stop_spoken_audio()
	if OS.has_feature("web"):
		return _speak_text_web(text)
	if not _tts_voice.is_empty():
		var volume := int(round(load_saved_volume() * 100.0))
		DisplayServer.tts_speak(text, _tts_voice, volume, 1.0, 0.92, 1, true)
		return true
	if OS.get_name() == "Windows":
		return _speak_text_windows(text)
	return false

func stop_voice() -> void:
	_stop_spoken_audio()

func _speak_text_web(text: String) -> bool:
	var safe_text := JSON.stringify(text)
	var volume := snappedf(load_saved_volume(), 0.01)
	var code := "window.speechSynthesis.cancel();"
	code += "const utterance = new SpeechSynthesisUtterance(" + safe_text + ");"
	code += "utterance.lang = 'pt-BR';"
	code += "utterance.rate = 0.92;"
	code += "utterance.pitch = 1.0;"
	code += "utterance.volume = " + str(volume) + ";"
	code += "window.speechSynthesis.speak(utterance);"
	JavaScriptBridge.eval(code)
	return true

func _speak_text_windows(text: String) -> bool:
	var escaped_text := text.replace("'", "''")
	var volume := int(round(load_saved_volume() * 100.0))
	var script := "Add-Type -AssemblyName System.Speech; "
	script += "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
	script += "try {$s.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::NotSet, [System.Speech.Synthesis.VoiceAge]::NotSet, 0, [System.Globalization.CultureInfo]::GetCultureInfo('pt-BR'))} catch {}; "
	script += "$s.Volume = %d; $s.Rate = -1; $s.Speak('%s');" % [volume, escaped_text]
	_windows_tts_pid = OS.create_process("powershell.exe", PackedStringArray(["-NoProfile", "-NonInteractive", "-Command", script]), true)
	return _windows_tts_pid > 0

func _play_remote_nonblocking(cache_key: String, url: String, player: AudioStreamPlayer, fallback_key: String = "", fallback_text: String = "") -> void:
	_stop_spoken_audio()
	var generation := _spoken_generation
	if _stream_cache.has(cache_key):
		player.stream = _stream_cache[cache_key]
		player.play()
		return
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if is_instance_valid(request):
			request.queue_free()
		if generation != _spoken_generation:
			return
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
			var stream := AudioStreamOggVorbis.load_from_buffer(body)
			if stream != null:
				_stream_cache[cache_key] = stream
				player.stream = stream
				player.play()
				return
		if not fallback_key.is_empty():
			var text := str(FALLBACK_TEXTS.get(fallback_key, ""))
			if not text.is_empty():
				speak_text(text)
		elif not fallback_text.is_empty():
			speak_text(fallback_text)
	, Object.CONNECT_ONE_SHOT)
	var error := request.request(url)
	if error != OK:
		request.queue_free()
		if not fallback_key.is_empty():
			var text := str(FALLBACK_TEXTS.get(fallback_key, ""))
			if not text.is_empty():
				speak_text(text)
		elif not fallback_text.is_empty():
			speak_text(fallback_text)

func _fetch_stream(cache_key: String, url: String) -> AudioStream:
	if _stream_cache.has(cache_key):
		return _stream_cache[cache_key]
	var request := HTTPRequest.new()
	add_child(request)
	var error := request.request(url)
	if error != OK:
		request.queue_free()
		return null
	var response: Array = await request.request_completed
	request.queue_free()
	var result := int(response[0])
	var response_code := int(response[1])
	var body: PackedByteArray = response[3]
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		return null
	var stream := AudioStreamOggVorbis.load_from_buffer(body)
	if stream != null:
		_stream_cache[cache_key] = stream
	return stream

func _stop_spoken_audio() -> void:
	_spoken_generation += 1
	voice_player.stop()
	syllable_player.stop()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.speechSynthesis.cancel();")
	if _windows_tts_pid > 0 and OS.get_name() == "Windows":
		OS.kill(_windows_tts_pid)
		_windows_tts_pid = -1
	if not _tts_voice.is_empty():
		DisplayServer.tts_stop()

func _find_portuguese_voice() -> String:
	var voices := DisplayServer.tts_get_voices_for_language("pt_BR")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("pt")
	if voices.is_empty():
		return ""
	return str(voices[0])
