extends Node2D

@onready var nap_meter: ProgressBar = $GameInfoLayer/NapMeter
@onready var lord: Node2D = $Target/Destoryer

@onready var flash_rect: ColorRect = $GameInfoLayer/FlashRect
@onready var score_label: Label = $GameInfoLayer/Score

@onready var game_over_container: PanelContainer = $GameInfoLayer/GameOver
@onready var game_over_score_label: Label = $GameInfoLayer/GameOver/MarginContainer/VBoxContainer/Score

@onready var game_pause_score_label: Label = $GameInfoLayer/GamePause/MarginContainer/VBoxContainer/Score
@onready var game_pause: PanelContainer = $GameInfoLayer/GamePause

@onready var attendant: CharacterBody2D = $Attendant
@onready var coins_label: Label = $GameInfoLayer/Coins/Label

const GOBLIN = preload("uid://c6mwmqi5mhmck")
const SHOP_ITEM = preload("uid://cegs1nif11y3e")

var flash_tween: Tween

var is_agitated = false
var is_game_over = false

func _ready():
	flash_rect.modulate.a = 0
	game_over_container.visible = false

func _physics_process(delta: float) -> void:
	update_score()

	if is_game_over or is_agitated or get_tree().paused:
		return
	
	var current_noise = 0.0
	for goblin in get_tree().get_nodes_in_group('noise_maker'):
		var dist = goblin.global_position.distance_to(lord.global_position)
		current_noise += 5000.0 / clamp(dist, 10.0, 2000.0)
	
	GameManager.current_noise_level = current_noise

	if current_noise <= 25:
		GameManager.nap_level += 10.0 * delta
	else:
		GameManager.nap_level -= 5.0 * delta

	GameManager.nap_level = clamp(GameManager.nap_level, 0, 100)
	nap_meter.value = GameManager.nap_level
	
	if GameManager.nap_level <= 0:
		trigger_game_over()
	elif GameManager.nap_level <= 20:
		lord.play_anim("awake")
	else:
		lord.play_anim("sleep")

	if GameManager.nap_level <= 35 and GameManager.nap_level > 0:
		trigger_red_flash()
	else:
		reset_red_flash()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func update_score():
	score_label.text = str(GameManager.current_score)
	coins_label.text  = str(GameManager.current_coins) + "  "

func _on_quiet_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("noise_maker"):
		trigger_agitation()
		GameManager.nap_level -= 4

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
	GameManager.game_over_triggered.emit()
	
	lord.play_anim("fury")
	
	await get_tree().create_timer(3.0).timeout
	
	if attendant:
		attendant.set_physics_process(false)
		attendant.animated_sprite.stop()
	
	get_tree().call_group("noise_maker", "die")
	
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

func toggle_pause():
	if is_game_over: return
	
	var pause_state = not get_tree().paused
	
	get_tree().paused = pause_state
	game_pause.visible = pause_state
	
	if not pause_state:
		pass
	else:
		game_pause_score_label.text = str(GameManager.current_score)
		
	GameManager.game_paused.emit(pause_state)

func _on_resume_pressed() -> void:
	toggle_pause()
