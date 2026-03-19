extends Node

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var sounds = {
	"purchase": preload("res://assets/audio/cha-ching.mp3"), # Replace with your actual file paths
	"error": preload("res://assets/audio/error.mp3"),
	"game_over": preload("res://assets/audio/game-over.mp3")
}

func _ready() -> void:
	add_child(audio_stream_player_2d)
	
	GameManager.apply_item_effect.connect(_on_item_bought)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.failed_purchase.connect(_on_error)

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		audio_stream_player_2d.stream = sounds[sound_name]
		audio_stream_player_2d.play()

func _on_item_bought(_id: String):
	play_sound("purchase")

func _on_game_over():
	play_sound("game_over")
	
func _on_error():
	play_sound("error")
