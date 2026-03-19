extends CanvasLayer

@onready var game_over_container: PanelContainer = $GameOver
@onready var game_over_score_label: Label = $GameOver/MarginContainer/VBoxContainer/Score

@onready var game_pause_score_label: Label = $GamePause/MarginContainer/VBoxContainer/Score
@onready var game_pause: PanelContainer = $GamePause

@onready var nap_meter: ProgressBar = $NapMeter

@onready var score_label: Label = $Score
@onready var coins_label: Label = $Coins/Label

@onready var flash_rect: ColorRect = $FlashRect

var flash_tween: Tween

var is_game_over = false

func _ready() -> void:
	flash_rect.modulate.a = 0
	game_over_container.visible = false
	GameManager.game_over_triggered.connect(_on_game_over)

func _process(delta: float) -> void:
	update_score()
	nap_meter.value = GameManager.nap_level
	
	if GameManager.nap_level <= 35 and GameManager.nap_level > 0:
		trigger_red_flash()
	else:
		reset_red_flash()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func _on_game_over():
	game_over_container.visible = true
	score_label.text = str(GameManager.current_score)
	game_over_score_label.text = str(GameManager.current_score)

func _on_game_retry() -> void:
	get_tree().reload_current_scene()

func _on_resume_pressed() -> void:
	toggle_pause()

func update_score():
	score_label.text = str(GameManager.current_score)
	coins_label.text  = str(GameManager.current_coins) + "  "

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
