extends Node

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_path: Path2D = $SpawnPath
@onready var spawn_location: PathFollow2D = $SpawnPath/SpawnLocation

const GOBLIN = preload("uid://c6mwmqi5mhmck")

var spawn_rate = 4.0
var difficulty_time = 0.0

var is_game_over = false

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()
	GameManager.game_over_triggered.connect(_on_game_over)

func _process(delta: float) -> void:
	increase_diff(delta)
		
func _on_game_over():
	spawn_timer.stop()
	is_game_over = true
	
func _on_spawn_timer():
	if is_game_over:
		spawn_timer.stop()
		return
		
	if get_tree().paused:
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
	difficulty_time += delta
	if difficulty_time > 10.0 and spawn_rate > 0.5:
		difficulty_time = 0.0
		spawn_rate -= 0.1
		spawn_timer.wait_time = spawn_rate
