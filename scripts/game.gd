extends Node2D

@onready var lord: Node2D = $Target/Destoryer

@onready var attendant: CharacterBody2D = $Attendant

var aura_tween: Tween

var is_agitated = false
var is_game_over = false

var shake_intensity = 0.0

func _ready() -> void:
	GameManager.apply_item_effect.connect(_on_apply_item_effect)
	await get_tree().create_timer(.1).timeout
	GameManager.trigger_tutorial.emit(
	"welcome",
	"Protect the Sleeping Destroyer!\nKeep him asleep at all costs.",
	""
)

func _physics_process(delta: float) -> void:
	
	trigger_screen_shake()
	
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
		
	if GameManager.current_coins >= 50:
		GameManager.trigger_tutorial.emit(
			"shop",
			"You have enough coins!\nPress 'Y' to open the Yummy Shop \nand buy food to keep the Destroyer asleep!",
			"Y"
		)

func _on_apply_item_effect(id: String):
	match id:
		"pudding":
			GameManager.nap_level += 20.0
		"cake":
			GameManager.nap_level += 40.0
		"ramen":
			GameManager.nap_level = 100.0
		"healing":
			if attendant: attendant.heal()
		"portal":
			print("TODO: Implement Teleport")
		"time":
			print("TODO: Implement Time Freeze")
			
	GameManager.nap_level = clamp(GameManager.nap_level, 0, 100)

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
	shake_intensity = 15.0
	trigger_aura_flare()
	
	await get_tree().create_timer(3.0).timeout
	
	shake_intensity = 0.0
	var camera = get_viewport().get_camera_2d()
	if camera: camera.offset = Vector2.ZERO

	if aura_tween: aura_tween.kill()
	lord.modulate = Color.WHITE
		
	if attendant:
		attendant.set_physics_process(false)
		attendant.animated_sprite.stop()
	
	get_tree().call_group("noise_maker", "die")
	
func trigger_screen_shake():
	if shake_intensity > 0:
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)

func trigger_aura_flare():
	if aura_tween: aura_tween.kill()
	
	aura_tween = create_tween().set_loops()
	
	aura_tween.tween_property(lord, "modulate", Color(2.5, 0.5, 3.0, 1.0), 0.1)
	aura_tween.tween_property(lord, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
