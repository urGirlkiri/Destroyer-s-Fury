extends Node2D

@onready var nap_meter: ProgressBar = $GameInfoLayer/NapMeter
@onready var lord: Node2D = $Target/Destoryer

@onready var flash_rect: ColorRect = $GameInfoLayer/FlashRect
@onready var score_label: Label = $GameInfoLayer/Score

@onready var game_over_container: PanelContainer = $GameInfoLayer/GameOver
@onready var game_over_score_label: Label = $GameInfoLayer/GameOver/MarginContainer/VBoxContainer/Score

@onready var game_pause_score_label: Label = $GameInfoLayer/GamePause/MarginContainer/VBoxContainer/Score
@onready var game_pause: PanelContainer = $GameInfoLayer/GamePause

@onready var spawn_timer: Timer = $Spawn/SpawnTimer
@onready var spawn_path: Path2D = $Spawn/SpawnPath
@onready var spawn_location: PathFollow2D = $Spawn/SpawnPath/SpawnLocation

@onready var attendant: CharacterBody2D = $Attendant
@onready var coins_label: Label = $GameInfoLayer/Coins/Label

@onready var yummy_shop: Panel = $Shops/YummyShop
@onready var yummy_shop_list: VBoxContainer = $Shops/YummyShop/Items/VBoxContainer

@onready var power_shop: Panel = $Shops/PowerShop
@onready var power_shop_list: VBoxContainer = $Shops/PowerShop/Items/VBoxContainer

const GOBLIN = preload("uid://c6mwmqi5mhmck")
const SHOP_ITEM = preload("uid://cegs1nif11y3e")

var flash_tween: Tween

var nap_level = 100.0
var difficulty_time = 0.0
var spawn_rate = 4.0

var is_agitated = false
var is_game_over = false
var is_shop_open = false

func _ready():
	flash_rect.modulate.a = 0
	game_over_container.visible = false
	
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()
	
	for item_data in GameManager.yummy_stuff:
		var new_item = SHOP_ITEM.instantiate()
		yummy_shop_list.add_child(new_item)
		new_item.setup(item_data)
		new_item.item_clicked.connect(_on_shop_item_clicked)
		
	for item_data in GameManager.powerups:
		var new_item = SHOP_ITEM.instantiate()
		power_shop_list.add_child(new_item)
		new_item.setup(item_data)
		new_item.item_clicked.connect(_on_shop_item_clicked)

func _on_spawn_timer():
	if is_game_over or get_tree().paused:
		spawn_timer.stop()
		return

	var gob = GOBLIN.instantiate()
	spawn_location.progress_ratio = randf()
	gob.global_position = spawn_location.global_position
	add_child(gob)

func _physics_process(delta: float) -> void:
	update_score()

	if is_game_over or is_agitated or get_tree().paused:
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
	
	if event.is_action_pressed("yummy"):
		toggle_yummy_shop()

	if event.is_action_pressed("powerup"):
		toggle_power_shop()
		
func update_score():
	score_label.text = str(GameManager.current_score)
	coins_label.text  = str(GameManager.current_coins) + "  "

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
		is_shop_open = false
		yummy_shop.visible = false
		power_shop.visible = false
	
	if pause_state:
		game_pause_score_label.text = str(GameManager.current_score)

func _on_resume_pressed() -> void:
	toggle_pause()

func toggle_shop():
	if get_tree().paused and not is_shop_open:
		pass
	else:
		toggle_pause()
		
	is_shop_open = !is_shop_open

func toggle_yummy_shop():
	toggle_shop()
	yummy_shop.visible = is_shop_open
	
func toggle_power_shop():
	toggle_shop()
	power_shop.visible = is_shop_open
	
func _on_yummy_btn_pressed() -> void:
	toggle_yummy_shop()

func _on_power_btn_pressed() -> void:
	toggle_power_shop()


func _on_shop_item_clicked(id: String, price: int):
	if GameManager.current_coins >= price:
		GameManager.current_coins -= price
		update_score()
		apply_item_effect(id)
	else:
		print("Not enough coins!")

func apply_item_effect(id: String):
	print("Applying item effect: ", id)
	
	match id:
		"pudding":
			nap_level += 20.0
		"cake":
			nap_level += 40.0
		"ramen":
			nap_level = 100.0
			
		"healing":
			if attendant:
				attendant.max_ammo += 1
				attendant.current_ammo = attendant.max_ammo
		"portal":
			print("TODO: Implement Teleport")
		"time":
			print("TODO: Implement Time Freeze")
			
		_:
			print("Unknown item bought: ", id)
			
	nap_level = clamp(nap_level, 0, 100)
	nap_meter.value = nap_level
