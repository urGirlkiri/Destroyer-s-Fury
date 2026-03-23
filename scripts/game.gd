extends Node2D

@onready var lord: Node2D = $Target/Destoryer

@onready var attendant: CharacterBody2D = $Attendant

var aura_tween: Tween
var eat_tween: Tween


var is_agitated = false
var is_game_over = false

var shake_intensity = 0.0
var nap_drain_multiplier = 1.0
var food_buff_timer = 0.0

var pending_visuals = []
var pending_time_freeze = false 
var pending_teleport = false

func _ready() -> void:
	GameManager.apply_item_effect.connect(_on_apply_item_effect)
	GameManager.game_paused.connect(_on_game_paused)
	
	await get_tree().create_timer(.4).timeout
	GameManager.trigger_tutorial.emit(
	"welcome",
	"Protect the Sleeping Destroyer!\nKeep him asleep at all costs.",
	""
	)
	
	while get_tree().paused:
		await get_tree().process_frame
		
	await get_tree().create_timer(.2).timeout
	GameManager.wave_changed.emit(1)

func _physics_process(delta: float) -> void:
	
	trigger_screen_shake()
	
	if is_game_over or is_agitated or get_tree().paused:
		return
	
	if food_buff_timer > 0:
		food_buff_timer -= delta
		if food_buff_timer <= 0:
			nap_drain_multiplier = 1.0
			
	var current_noise = 0.0
	for goblin in get_tree().get_nodes_in_group('noise_maker'):
		var dist = goblin.global_position.distance_to(lord.global_position)
		current_noise += 5000.0 / clamp(dist, 10.0, 2000.0)
	
	GameManager.current_noise_level = current_noise

	if current_noise <= 25:
		GameManager.nap_level += 10.0 * delta
	else:
		GameManager.nap_level -= (5.0 * nap_drain_multiplier) * delta

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

func _on_game_paused(is_paused: bool):
	if not is_paused:
		if pending_visuals.size() > 0:
			for juice in pending_visuals:
				var target = juice.get("target", lord)
				
				if target == lord:
					trigger_eat_glow()
					
				spawn_floating_text(juice["text"], juice["color"], target)
				
			pending_visuals.clear()
			
		if pending_time_freeze:
			pending_time_freeze = false
			trigger_time_freeze()
			
		if pending_teleport:
			pending_teleport = false
			attendant.activate_teleport_mode()
			
			GameManager.trigger_tutorial.emit(
				"teleport",
				"Move Cursor To The Location And Click To Teleport",
				""
			)
		
func _on_apply_item_effect(id: String):
	match id:
		"pudding":
			GameManager.nap_level += 20.0
			nap_drain_multiplier = 0.5
			food_buff_timer = 15.0
			queue_visual_juice("+20 Nap!", Color.GREEN) 
			
		"cake":
			GameManager.nap_level += 40.0
			nap_drain_multiplier = 0.0
			food_buff_timer = 8.0
			queue_visual_juice("+40 Nap (Immune!)", Color.ORANGE) 
			
		"ramen":
			GameManager.nap_level = 100.0
			queue_visual_juice("MAX NAP!", Color.GOLD) 
			
		"healing":
			if attendant:
				attendant.heal()
				queue_visual_juice("+ Blasting Restored", Color.CYAN, attendant) 
				
		"portal":
			queue_visual_juice("TELEPORT READY!", Color.PURPLE, attendant)
			
			if get_tree().paused:
				pending_teleport = true
			else:
				attendant.activate_teleport_mode()
		"time":
			queue_visual_juice("TIME FREEZE!", Color.AQUA, attendant)
			
			if get_tree().paused:
				pending_time_freeze = true
			else:
				trigger_time_freeze() 
			
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

func trigger_eat_glow():
	if eat_tween: eat_tween.kill()
	eat_tween = create_tween()
	
	eat_tween.tween_property(lord, "modulate", Color(1.8, 1.2, 0.2, 1.0), 0.15)
	eat_tween.tween_property(lord, "modulate", Color.WHITE, 0.3)

func queue_visual_juice(text: String, color: Color, target: Node2D = lord):
	if get_tree().paused:
		pending_visuals.append({"text": text, "color": color, "target": target})
	else:
		if target == lord:
			trigger_eat_glow() 
			
		spawn_floating_text(text, color, target)

func trigger_time_freeze():
	GameManager.is_time_frozen = true
	
	var goblins = get_tree().get_nodes_in_group('noise_maker')
	for goblin in goblins:
		if is_instance_valid(goblin):
			goblin.is_frozen = true
			if goblin.has_node("AnimatedSprite2D"):
				goblin.get_node("AnimatedSprite2D").modulate = Color(0.5, 0.8, 1.0)
			
	await get_tree().create_timer(GameManager.TIME_TO_FREEZE, false).timeout
			
	GameManager.is_time_frozen = false
	
	goblins = get_tree().get_nodes_in_group('noise_maker')
	for goblin in goblins:
		if is_instance_valid(goblin):
			goblin.is_frozen = false
			if goblin.has_node("AnimatedSprite2D"):
				goblin.get_node("AnimatedSprite2D").modulate = Color.WHITE
				goblin.get_node("AnimatedSprite2D").play() # Unpause the animation
		
func spawn_floating_text(text: String, color: Color, target: Node2D = lord):
	var float_label = Label.new()
	float_label.text = text
	float_label.modulate = color
	float_label.scale = Vector2(1.5, 1.5)
	
	var random_x = randf_range(-60, 0)
	var random_y = randf_range(-70, -30)

	float_label.global_position = target.global_position + Vector2(random_x, random_y)
	add_child(float_label)

	var float_tween = create_tween()
	float_tween.tween_property(float_label, "global_position:y", float_label.global_position.y - 80, 1.2)
	float_tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.2)
	float_tween.tween_callback(float_label.queue_free)
