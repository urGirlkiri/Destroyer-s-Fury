extends Node2D

@onready var lord: Node2D = $Target/Destoryer

@onready var attendant: CharacterBody2D = $Attendant

var is_agitated = false
var is_game_over = false

func _physics_process(delta: float) -> void:
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
	
	if GameManager.nap_level <= 0:
		trigger_game_over()
	elif GameManager.nap_level <= 20:
		lord.play_anim("awake")
	else:
		lord.play_anim("sleep")	

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
	
