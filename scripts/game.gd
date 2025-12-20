extends Node2D

@onready var nap_meter: ProgressBar = $GameInfoLayer/NapMeter
@onready var lord: Node2D = $Destoryer 
@onready var flash_rect: ColorRect = $GameInfoLayer/FlashRect
@onready var game_over_container: PanelContainer = $GameInfoLayer/GameOver
@onready var score_label: Label = $GameInfoLayer/Score
@onready var game_over_score_label: Label = $GameInfoLayer/GameOver/MarginContainer/VBoxContainer/Score

var nap_level = 100.0
var is_agitated = false 
var awake = false
var score = 0

var flash_tween: Tween

func _ready():
	flash_rect.modulate.a = 0
	game_over_container.visible = false

func _physics_process(delta: float) -> void:
	update_score()
	
	var current_noise = 0.0
	
	for goblin in get_tree().get_nodes_in_group('goblins'):
		var dist = goblin.global_position.distance_to(lord.global_position)
		current_noise += 5000.0 / clamp(dist, 10.0, 2000.0)
	
	GameManager.current_noise_level = current_noise

	if current_noise <= 25:
		nap_level += 10.0 * delta 
	else:
		nap_level -= 5.0 * delta 

	nap_level = clamp(nap_level, 0, 100)
	nap_meter.value = nap_level
	
	if is_agitated:
		return

	if nap_level <= 0:
		lord.play_anim("fury")    
		await get_tree().create_timer(3.0).timeout
		game_over()

	elif not awake:
		if nap_level <= 20:
			lord.play_anim("awake")
			awake = true
		elif nap_level > 0:
			if nap_level <= 50:
				trigger_agitation()
			
			if nap_level <= 35:
				trigger_red_flash()
		else:
			lord.play_anim("sleep")  
	
	else:
		reset_red_flash()

func _on_quiet_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("noise_maker"):
		trigger_agitation()
		nap_level -= 4

func trigger_agitation():
	if is_agitated or nap_level == 0 and not awake:
		return
		
	is_agitated = true
	lord.play_anim("agitated")
	await get_tree().create_timer(1.0).timeout
	is_agitated = false

func reset_red_flash():
	if flash_rect.modulate.a == 0:
		if flash_tween: flash_tween.kill()
		flash_tween = null
		return

	if flash_tween:
		flash_tween.kill()
	
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

func game_over():
	game_over_container.visible = true
	game_over_score_label.text = str(score)

func _on_game_retry() -> void:
	get_tree().reload_current_scene()

func update_score():
	score_label.text = str(score)
