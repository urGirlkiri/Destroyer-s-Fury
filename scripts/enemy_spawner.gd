extends Node

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_path: Path2D = $SpawnPath
@onready var spawn_location: PathFollow2D = $SpawnPath/SpawnLocation

const GOBLIN = preload("uid://c6mwmqi5mhmck")

var spawn_rate = 6.0
var wave_timer = 0.0
const TIME_BETWEEN_WAVES = 30.0 

var is_game_over = false

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()
	GameManager.game_over_triggered.connect(_on_game_over)

func _process(delta: float) -> void:
	if is_game_over or get_tree().paused or GameManager.is_time_frozen:
		return
		
	increase_diff(delta)
	
func _on_game_over():
	spawn_timer.stop()
	is_game_over = true
	
func _on_spawn_timer():
	if is_game_over or get_tree().paused or GameManager.is_time_frozen:
		return

	var gob = GOBLIN.instantiate()
	spawn_location.progress_ratio = randf()
	gob.global_position = spawn_location.global_position
	add_child(gob)
	
	GameManager.trigger_tutorial.emit(
		"first_goblin",
		"Goblin Approaching!\n\nPress 'S' + Arrow to fire a Blast In Its Direction.\n",
		"S"
	)

func increase_diff(delta: float):
	wave_timer += delta
	
	if wave_timer >= TIME_BETWEEN_WAVES:
		wave_timer = 0.0 
		
		GameManager.current_wave += 1
		
		GameManager.wave_changed.emit(GameManager.current_wave)
		
		spawn_rate = max(0.8, spawn_rate - 0.5)
		spawn_timer.wait_time = spawn_rate
		
		print("Starting Wave: ", GameManager.current_wave, " | New Spawn Rate: ", spawn_rate)
