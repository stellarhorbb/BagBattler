extends Node

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.volume_db = -6.0

func play_menu() -> void:
	_play("res://assets/music/pufino_careful.mp3", false)

func play_game() -> void:
	_play("res://assets/music/in-game-music.mp3", true)

func stop(fade_duration: float = 0.8) -> void:
	if not _player.playing:
		return
	var t = create_tween()
	t.tween_property(_player, "volume_db", -60.0, fade_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(_player.stop)

func _play(path: String, loop: bool) -> void:
	var stream = load(path)
	stream.loop = loop
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	_player.volume_db = -6.0
	_player.play()
