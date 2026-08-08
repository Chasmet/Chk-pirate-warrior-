class_name VoiceFR
extends RefCounted

static var enabled := true
static var voice_id := ""

static func initialize(active: bool = true) -> void:
	enabled = active
	if not enabled:
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices := DisplayServer.tts_get_voices_for_language("fr")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("fr_FR")
	if not voices.is_empty():
		voice_id = voices[0]

static func speak(text: String, interrupt: bool = true) -> void:
	if not enabled or text.is_empty() or voice_id.is_empty():
		return
	DisplayServer.tts_speak(text, voice_id, 82, 0.95, 0.94, 0, interrupt)

static func stop() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
