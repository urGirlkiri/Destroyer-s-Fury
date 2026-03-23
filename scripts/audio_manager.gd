extends Node

@onready var sfx: AudioStreamPlayer = $SFX
@onready var music: AudioStreamPlayer2D = $Music

var sounds = {
	"purchase": preload("res://assets/audio/cha-ching.mp3"), # Replace with your actual file paths
	"error": preload("res://assets/audio/error.mp3"),
	"game_over": preload("res://assets/audio/game-over.mp3"),
	"bg_music": preload("res://assets/audio/epic-cover.mp3"),
	
	"chew_soft": preload("res://assets/audio/chewing.mp3"), 
	"slurp": preload("res://assets/audio/slurp.mp3"),
	"yummy": preload("res://assets/audio/yummy.mp3")
}

func _ready() -> void:	
	GameManager.apply_item_effect.connect(_on_item_bought)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.failed_purchase.connect(_on_error)
	
	play_music("bg_music")

func _on_item_bought(id: String):
	for item in GameManager.yummy_stuff:
		if (item["id"] == id):
			if(item["sfx"]):
				play_sound(item["sfx"])
			else:
				play_sound("purchase")
			break

func _on_game_over():
	play_sound("game_over")
	music.pitch_scale = 0.5
	
func _on_error():
	play_sound("error")

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		sfx.stream = sounds[sound_name]
		sfx.volume_db = -5.0
		sfx.play()

func play_music(track_name: String):
	if sounds.has(track_name):
		music.stream = sounds[track_name]
		music.volume_db = 2.0 
		music.play()
