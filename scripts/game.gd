extends Node2D

@onready var nap_meter: ProgressBar = $GameInfoLayer/NapMeter
@onready var lord: Node2D = $Destoryer 

@onready var flash_rect: ColorRect = $GameInfoLayer/FlashRect
@onready var score_label: Label = $GameInfoLayer/Score

@onready var game_over_container: PanelContainer = $GameInfoLayer/GameOver
@onready var game_over_score_label: Label = $GameInfoLayer/GameOver/MarginContainer/VBoxContainer/Score

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_path: Path2D = $SpawnPath
@onready var spawn_location: PathFollow2D = $SpawnPath/SpawnLocation

const GOBLIN = preload("uid://c6mwmqi5mhmck")

var nap_level = 100.0
var is_agitated = false 
var is_game_over = false 

var flash_tween: Tween

var difficulty_time = 0.0
var spawn_rate = 4.0

func _ready():
	flash_rect.modulate.a = 0
	game_over_container.visible = false
	
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()

func _on_spawn_timer():
	if is_game_over:
		spawn_timer.stop()
		return

	var gob = GOBLIN.instantiate()
	spawn_location.progress_ratio = randf()
	gob.global_position = spawn_location.global_position
	add_child(gob)

func _physics_process(delta: float) -> void:
	update_score()

	if is_game_over or is_agitated:
		return

	increase_diff(delta)
	
	var current_noise = 0.0
	for goblin in get_tree().get_nodes_in_group('noise_maker'): 
		var dist = goblin.global_position.distance_to(lord.global_position)
		current_noise += 5000.0 / clamp(dist, 10.0, 2000.0)
	
	GameManager.current_noise_level = current_noise

	if current_noise <= 25:
		nap_level += 10.0 * delta 
	else:
		nap_level -= 5.0 * delta 

	nap_level = clamp(nap_level, 0, 100)
	nap_meter.value = nap_level
	
	
	if nap_level <= 0:
		trigger_game_over()

	elif nap_level <= 20:
		lord.play_anim("awake")
		
	else:
		lord.play_anim("sleep")

	if nap_level <= 35 and nap_level > 0:
		trigger_red_flash()
	else:
		reset_red_flash()

func update_score():
	score_label.text = str(GameManager.current_score)

func increase_diff(delta: float):
	difficulty_time += delta
	if difficulty_time > 10.0 and spawn_rate > 0.5:
		difficulty_time = 0.0
		spawn_rate -= 0.1 
		spawn_timer.wait_time = spawn_rate

func _on_quiet_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("noise_maker"):
		trigger_agitation()
		nap_level -= 4

func trigger_agitation():
	if is_agitated or is_game_over:
		return
		
	is_agitated = true
	lord.play_anim("agitated")
	
	await get_tree().create_timer(1.0).timeout
	
	if not is_game_over:
		is_agitated = false

func trigger_game_over():
	if is_game_over:
		return
		
	is_game_over = true
	
	spawn_timer.stop() 
	lord.play_anim("fury")    
	
	await get_tree().create_timer(3.0).timeout
	game_over()

func game_over():
	game_over_container.visible = true
	score_label.text = str(GameManager.current_score)
	game_over_score_label.text = str(GameManager.current_score)

func _on_game_retry() -> void:
	get_tree().reload_current_scene()
	
func reset_red_flash():
	if flash_rect.modulate.a == 0:
		if flash_tween: flash_tween.kill()
		flash_tween = null
		return
	if flash_tween: flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.5)

func trigger_red_flash():
	if flash_tween and flash_tween.is_valid() and flash_tween.get_loops_left() < 0:
		return
	if flash_tween: flash_tween.kill()
	flash_tween = create_tween().set_loops()
	flash_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	flash_tween.tween_property(flash_rect, "modulate:a", 0.3, 1.0)
	flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 1.0)
