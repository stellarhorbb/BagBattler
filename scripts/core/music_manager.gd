extends Node

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func play_menu() -> void:
	_play("res://assets/music/pufino_careful.mp3", false, -6.0)

func play_game() -> void:
	pass  # muted for now

func stop(fade_duration: float = 0.8) -> void:
	if not _player.playing:
		return
	var t = create_tween()
	t.tween_property(_player, "volume_db", -60.0, fade_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(_player.stop)

func _play(path: String, loop: bool, volume_db: float) -> void:
	var stream = load(path)
	stream.loop = loop
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()
