extends Node
class_name AccessibilityAudio

const SETTINGS_PATH := "user://zoo_settings.cfg"
const MARIN_MANIFEST_PATH := "res://audio/marin/manifest.json"

# Temporary compatibility sources. They are used only while the complete Marin
# pack is not present. Once every manifest file exists, runtime speech is 100%
# local Marin and these sources are never selected.
const NINO_A_BASE := "https://raw.githubusercontent.com/RafaelTomazGraciano/ninoedu/main/assets/Vogal_A/Audios/"
const NINO_O_WORDS_BASE := "https://raw.githubusercontent.com/RafaelTomazGraciano/ninoedu/main/assets/Vogal_O/AudiosPalavras/"
const LIGUE_AUDIO_BASE := "https://raw.githubusercontent.com/RafaelTomazGraciano/ligue-as-silabas/main/assets/audios/"

const LEGACY_REMOTE_VOICES := {
	"menu_play": LIGUE_AUDIO_BASE + "jogar.ogg",
	"menu_how_to_play": LIGUE_AUDIO_BASE + "como_jogar.ogg",
	"ui_volume": LIGUE_AUDIO_BASE + "volume.ogg",
	"ui_back_menu": LIGUE_AUDIO_BASE + "voltar.ogg",
	"ui_help": LIGUE_AUDIO_BASE + "como_jogar.ogg",
	"ui_skip": LIGUE_AUDIO_BASE + "como_jogar/pular_tutorial.ogg",
	"tutorial_welcome": LIGUE_AUDIO_BASE + "como_jogar/vamos_aprender_a_jogar.ogg",
	"feedback_correct": LIGUE_AUDIO_BASE + "como_jogar/voce_acertou.ogg",
	"feedback_try_again": LIGUE_AUDIO_BASE + "como_jogar/tente_outra_vez.ogg",
	"tutorial_your_turn": LIGUE_AUDIO_BASE + "como_jogar/sua_vez.ogg"
}

const LEGACY_LOCAL_VOICES := {
	"tutorial_look_animal": "res://audio/voice/tutorial_look_animal.ogg",
	"tutorial_word_missing": "res://audio/voice/tutorial_word_missing.ogg",
	"tutorial_choose_ca": "res://audio/voice/tutorial_choose_ca.ogg",
	"final_complete": "res://audio/voice/final_congratulations.ogg",
	"final_play_again": "res://audio/voice/final_play_again.ogg",
	"final_back_menu": "res://audio/voice/final_back_menu.ogg"
}

const LEGACY_WORDS := {
	"CACHORRO": "res://audio/words/cachorro.ogg",
	"GATO": "res://audio/words/gato.ogg",
	"MACACO": "res://audio/words/macaco.ogg",
	"BALEIA": "res://audio/words/baleia.ogg",
	"CAVALO": "res://audio/words/cavalo.ogg",
	"GALINHA": "res://audio/words/galinha.ogg",
	"TARTARUGA": "res://audio/words/tartaruga.ogg"
}

const FALLBACK_TEXTS := {
	"menu_title": "Zoológico das Sílabas.",
	"menu_play": "Jogar.",
	"menu_how_to_play": "Como jogar.",
	"ui_volume": "Volume.",
	"ui_back_menu": "Voltar ao menu.",
	"ui_help": "Como jogar.",
	"ui_skip": "Pular.",
	"ui_repeat": "Ouvir novamente.",
	"tutorial_welcome": "Vamos aprender a jogar!",
	"tutorial_look_animal": "Olhe o animal.",
	"tutorial_word_missing": "Uma parte da palavra está faltando.",
	"tutorial_choose_ca": "Escolha a sílaba CA.",
	"feedback_correct": "Você acertou!",
	"feedback_try_again": "Tente outra vez.",
	"tutorial_your_turn": "Sua vez!",
	"final_title": "Parabéns!",
	"final_complete": "Você completou o Zoológico das Sílabas!",
	"final_play_again": "Jogar de novo.",
	"final_back_menu": "Voltar ao menu."
}

static var _stream_cache: Dictionary = {}

var voice_player := AudioStreamPlayer.new()
var syllable_player := AudioStreamPlayer.new()
var sfx_player := AudioStreamPlayer.new()

var _tts_voice := ""
var _last_nonzero_volume := 0.8
var _spoken_generation := 0

var _marin_entries: Dictionary = {}
var _marin_missing: Array[String] = []
var _marin_ready := false

func _ready() -> void:
	add_child(voice_player)
	add_child(syllable_player)
	add_child(sfx_player)
	_load_marin_manifest()
	_tts_voice = _find_portuguese_voice()
	var saved := load_saved_volume()
	if saved > 0.001:
		_last_nonzero_volume = saved
	set_master_volume(saved)

func is_marin_ready() -> bool:
	return _marin_ready

func get_missing_marin_files() -> Array[String]:
	return _marin_missing.duplicate()

func get_display_text(key: String, default_text: String = "") -> String:
	var entry := _get_marin_entry(key)
	if not entry.is_empty():
		return str(entry.get("display", default_text))
	return default_text

func get_spoken_text(key: String, default_text: String = "") -> String:
	var entry := _get_marin_entry(key)
	if not entry.is_empty():
		return str(entry.get("speech", default_text))
	return str(FALLBACK_TEXTS.get(key, default_text))

func get_word_display(word: String) -> String:
	var normalized := word.strip_edges().to_lower()
	return get_display_text("word_" + normalized, word.to_upper())

func get_syllable_display(syllable: String) -> String:
	var normalized := syllable.strip_edges().to_lower()
	return get_display_text("syllable_" + normalized, syllable.to_upper())

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
	if _marin_ready:
		return _play_marin_nonblocking(key, voice_player)
	return _play_legacy_voice(key)

func speak_and_wait(key: String, fallback_seconds: float = 1.2) -> void:
	if _marin_ready:
		var stream := _get_marin_stream(key)
		if stream != null:
			await _play_stream_and_wait(stream, voice_player)
			return
		return

	var local_stream := _get_legacy_local_voice_stream(key)
	if local_stream != null:
		await _play_stream_and_wait(local_stream, voice_player)
		return

	var url := str(LEGACY_REMOTE_VOICES.get(key, ""))
	if not url.is_empty():
		var remote_stream := await _fetch_stream("legacy_voice:" + key, url)
		if remote_stream != null:
			await _play_stream_and_wait(remote_stream, voice_player)
			return

	var text := str(FALLBACK_TEXTS.get(key, ""))
	if not text.is_empty() and speak_text(text):
		await get_tree().create_timer(fallback_seconds).timeout

func play_syllable(syllable: String) -> bool:
	var normalized := syllable.strip_edges().to_lower()
	if _marin_ready:
		return _play_marin_nonblocking("syllable_" + normalized, syllable_player)
	_play_remote_nonblocking(
		"legacy_syllable:" + normalized,
		NINO_A_BASE + normalized + ".ogg",
		syllable_player,
		syllable.to_upper()
	)
	return true

func play_syllable_and_wait(syllable: String, fallback_seconds: float = 0.7) -> void:
	var normalized := syllable.strip_edges().to_lower()
	if _marin_ready:
		var local_stream := _get_marin_stream("syllable_" + normalized)
		if local_stream != null:
			await _play_stream_and_wait(local_stream, syllable_player)
		return

	var stream := await _fetch_stream(
		"legacy_syllable:" + normalized,
		NINO_A_BASE + normalized + ".ogg"
	)
	if stream != null:
		await _play_stream_and_wait(stream, syllable_player)
		return
	if speak_text(syllable.to_upper()):
		await get_tree().create_timer(fallback_seconds).timeout

func play_word(word: String) -> bool:
	var normalized := word.strip_edges().to_upper()
	if _marin_ready:
		return _play_marin_nonblocking("word_" + normalized.to_lower(), voice_player)

	var local_stream := _get_legacy_word_stream(normalized)
	if local_stream != null:
		_stop_spoken_audio()
		voice_player.stream = local_stream
		voice_player.play()
		return true
	return speak_text(word.capitalize())

func play_word_and_wait(word: String, fallback_seconds: float = 1.0) -> void:
	var normalized := word.strip_edges().to_upper()
	if _marin_ready:
		var marin_stream := _get_marin_stream("word_" + normalized.to_lower())
		if marin_stream != null:
			await _play_stream_and_wait(marin_stream, voice_player)
		return

	var local_stream := _get_legacy_word_stream(normalized)
	if local_stream != null:
		await _play_stream_and_wait(local_stream, voice_player)
		return
	if speak_text(word.capitalize()):
		await get_tree().create_timer(fallback_seconds).timeout

func stop_voice() -> void:
	_stop_spoken_audio()

func speak_text(text: String) -> bool:
	if _tts_voice.is_empty():
		return false
	_stop_spoken_audio()
	var volume := int(round(load_saved_volume() * 100.0))
	DisplayServer.tts_speak(text, _tts_voice, volume, 1.0, 0.92, 1, true)
	return true

func _load_marin_manifest() -> void:
	_marin_entries.clear()
	_marin_missing.clear()
	_marin_ready = false

	if not FileAccess.file_exists(MARIN_MANIFEST_PATH):
		push_warning("Marin manifest not found. Legacy audio compatibility mode is active.")
		return

	var file := FileAccess.open(MARIN_MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open Marin manifest. Legacy audio compatibility mode is active.")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("Invalid Marin manifest JSON. Legacy audio compatibility mode is active.")
		return

	var clips = parsed.get("clips", {})
	if not (clips is Dictionary) or clips.is_empty():
		push_warning("Marin manifest contains no clips. Legacy audio compatibility mode is active.")
		return

	_marin_entries = clips
	var unique_paths: Dictionary = {}
	for key in _marin_entries.keys():
		var entry = _marin_entries[key]
		if not (entry is Dictionary):
			_marin_missing.append("invalid entry: " + str(key))
			continue
		var path := str(entry.get("file", ""))
		if path.is_empty():
			_marin_missing.append("missing file path: " + str(key))
			continue
		unique_paths[path] = true

	for path in unique_paths.keys():
		if not ResourceLoader.exists(str(path)):
			_marin_missing.append(str(path))

	_marin_ready = _marin_missing.is_empty()
	if _marin_ready:
		print("Marin voice pack ready: ", unique_paths.size(), " local clips.")
	else:
		push_warning(
			"Marin voice pack incomplete (" + str(_marin_missing.size()) +
			" missing). Legacy audio compatibility mode is active."
		)

func _get_marin_entry(key: String) -> Dictionary:
	var value = _marin_entries.get(key, {})
	if value is Dictionary:
		return value
	return {}

func _get_marin_stream(key: String) -> AudioStream:
	var entry := _get_marin_entry(key)
	if entry.is_empty():
		return null
	var path := str(entry.get("file", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _play_marin_nonblocking(key: String, player: AudioStreamPlayer) -> bool:
	var stream := _get_marin_stream(key)
	if stream == null:
		return false
	_stop_spoken_audio()
	player.stream = stream
	player.play()
	return true

func _play_legacy_voice(key: String) -> bool:
	var local_stream := _get_legacy_local_voice_stream(key)
	if local_stream != null:
		_stop_spoken_audio()
		voice_player.stream = local_stream
		voice_player.play()
		return true

	var url := str(LEGACY_REMOTE_VOICES.get(key, ""))
	if not url.is_empty():
		_play_remote_nonblocking("legacy_voice:" + key, url, voice_player, str(FALLBACK_TEXTS.get(key, "")))
		return true

	var text := str(FALLBACK_TEXTS.get(key, ""))
	if not text.is_empty():
		return speak_text(text)
	return false

func _get_legacy_local_voice_stream(key: String) -> AudioStream:
	var path := str(LEGACY_LOCAL_VOICES.get(key, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _get_legacy_word_stream(normalized_word: String) -> AudioStream:
	var path := str(LEGACY_WORDS.get(normalized_word, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _play_stream_and_wait(stream: AudioStream, player: AudioStreamPlayer) -> void:
	_stop_spoken_audio()
	var generation := _spoken_generation
	player.stream = stream
	player.play()
	while player.playing and generation == _spoken_generation:
		await get_tree().process_frame

func _play_remote_nonblocking(cache_key: String, url: String, player: AudioStreamPlayer, fallback_text: String = "") -> void:
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
		if not fallback_text.is_empty():
			speak_text(fallback_text)
	, Object.CONNECT_ONE_SHOT)

	var error := request.request(url)
	if error != OK:
		request.queue_free()
		if not fallback_text.is_empty():
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
	if not _tts_voice.is_empty():
		DisplayServer.tts_stop()

func _find_portuguese_voice() -> String:
	var voices := DisplayServer.tts_get_voices_for_language("pt_BR")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("pt")
	if voices.is_empty():
		return ""
	return str(voices[0])
