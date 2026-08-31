extends Node
class_name AccessibilityAudio

const SETTINGS_PATH := "user://zoo_settings.cfg"

var voice_player := AudioStreamPlayer.new()
var music_player := AudioStreamPlayer.new()
var sfx_player := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(voice_player)
	add_child(music_player)
	add_child(sfx_player)
	set_master_volume(load_saved_volume())

func set_master_volume(value: float) -> void:
	var safe_value: float = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(0, safe_value <= 0.001)
	if safe_value > 0.001:
		AudioServer.set_bus_volume_db(0, linear_to_db(safe_value))

func save_master_volume(value: float) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "master_volume", clampf(value, 0.0, 1.0))
	config.save(SETTINGS_PATH)
	set_master_volume(value)

func load_saved_volume() -> float:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return 0.8
	return float(config.get_value("audio", "master_volume", 0.8))

func play_voice(key: String) -> bool:
	var path := _find_audio_file("res://audio/voice/" + key)
	if path.is_empty():
		return false
	voice_player.stop()
	voice_player.stream = load(path)
	voice_player.play()
	return true

func speak_and_wait(key: String, fallback_seconds: float = 1.2) -> void:
	if play_voice(key):
		await voice_player.finished
	else:
		await get_tree().create_timer(fallback_seconds).timeout

func stop_voice() -> void:
	voice_player.stop()

func play_music(key: String) -> bool:
	var path := _find_audio_file("res://audio/music/" + key)
	if path.is_empty():
		return false
	if music_player.playing:
		return true
	music_player.stream = load(path)
	music_player.volume_db = -16.0
	music_player.play()
	return true

func stop_music() -> void:
	music_player.stop()

func _find_audio_file(base_path: String) -> String:
	for extension in [".ogg", ".wav", ".mp3"]:
		var candidate: String = base_path + str(extension)
		if FileAccess.file_exists(candidate):
			return candidate
	return ""
