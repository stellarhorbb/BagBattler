extends Node

const SOUNDS := {
	"draw":                 "res://assets/sfx/draw.wav",
	"resolution":           "res://assets/sfx/resolution.wav",
	"pressure-resolution":  "res://assets/sfx/pressure-resolution.wav",
	"crash":                "res://assets/sfx/crash.wav",
	"hazard":               "res://assets/sfx/hazard.wav",
	"damage":               "res://assets/sfx/damage.wav",
	"safe":                 "res://assets/sfx/safe.wav",
	"saved":                "res://assets/sfx/saved.wav",
}

var _players: Array[AudioStreamPlayer] = []
var _pool_size: int = 6

func _ready() -> void:
	for i in _pool_size:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)

func play(sound: String) -> void:
	if not SOUNDS.has(sound):
		return
	var player := _get_free_player()
	if player == null:
		return
	player.stream = load(SOUNDS[sound])
	player.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]
