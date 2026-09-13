extends Node
class_name AccessibilityAudio

const SETTINGS_PATH := "user://zoo_settings.cfg"

var voice_player := AudioStreamPlayer.new()
var music_player := AudioStreamPlayer.new()
var sfx_player := AudioStreamPlayer.new()

var _last_non_zero_volume := 0.85

func _ready() -> void:
	add_child(voice_player)
	add_child(music_player)
	add_child(sfx_player)
	set_master_volume(load_saved_volume())
	_apply_saved_mute_state()

func set_master_volume(value: float) -> void:
	var safe_value := clampf(value, 0.0, 1.0)
	if safe_value > 0.001:
		_last_non_zero_volume = safe_value
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(safe_value, 0.001)))
	AudioServer.set_bus_mute(0, safe_value <= 0.001 or is_muted())

func save_master_volume(value: float) -> void:
	var safe_value := clampf(value, 0.0, 1.0)
	var config := _load_config()
	config.set_value("audio", "master_volume", safe_value)
	config.save(SETTINGS_PATH)
	set_master_volume(safe_value)

func load_saved_volume() -> float:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return 0.85
	return float(config.get_value("audio", "master_volume", 0.85))

func set_muted(muted: bool) -> void:
	var config := _load_config()
	config.set_value("audio", "muted", muted)
	config.save(SETTINGS_PATH)
	AudioServer.set_bus_mute(0, muted or load_saved_volume() <= 0.001)

func toggle_muted() -> bool:
	set_muted(not is_muted())
	return is_muted()

func is_muted() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	return bool(config.get_value("audio", "muted", false))

func play_syllable(syllable: String) -> bool:
	if is_muted():
		return false
	var normalized := syllable.strip_edges().to_lower()
	var path := _find_audio_file("res://audio/syllables/" + normalized)
	if path.is_empty():
		path = _find_audio_file("res://audio/voice/syllable_" + normalized)
	return _play_on(sfx_player, path)

func play_word(word: String) -> bool:
	if is_muted():
		return false
	var normalized := word.strip_edges().to_lower()
	var path := _find_audio_file("res://audio/words/" + normalized)
	if path.is_empty():
		path = _find_audio_file("res://audio/voice/animal_" + normalized)
	return _play_on(voice_player, path)

# Compatibility with the previous project API. Missing narration is intentionally
# non-fatal: the rebuilt UI always communicates instructions visually as well.
func play_voice(key: String) -> bool:
	if is_muted():
		return false
	return _play_on(voice_player, _find_audio_file("res://audio/voice/" + key))

func speak_and_wait(key: String, fallback_seconds: float = 0.5) -> void:
	if play_voice(key):
		await voice_player.finished
	else:
		await get_tree().create_timer(fallback_seconds).timeout

func stop_voice() -> void:
	voice_player.stop()

func play_music(key: String) -> bool:
	if is_muted():
		return false
	var path := _find_audio_file("res://audio/music/" + key)
	if path.is_empty():
		return false
	if music_player.playing and music_player.stream == load(path):
		return true
	music_player.stop()
	music_player.stream = load(path)
	music_player.volume_db = -16.0
	music_player.play()
	return true

func stop_music() -> void:
	music_player.stop()

func _play_on(player: AudioStreamPlayer, path: String) -> bool:
	if path.is_empty():
		return false
	var stream = load(path)
	if stream == null:
		return false
	player.stop()
	player.stream = stream
	player.play()
	return true

func _find_audio_file(base_path: String) -> String:
	for extension in [".ogg", ".wav", ".mp3"]:
		var candidate := base_path + extension
		if FileAccess.file_exists(candidate):
			return candidate
	return ""

func _load_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	return config

func _apply_saved_mute_state() -> void:
	AudioServer.set_bus_mute(0, is_muted() or load_saved_volume() <= 0.001)
