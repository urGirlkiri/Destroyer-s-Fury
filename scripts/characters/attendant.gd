extends CharacterBody2D

const SPEED = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var staff_radius: Area2D = $StaffRadius
@onready var ammo_bar: ProgressBar = $AmmoBar
@onready var weakness_timer: Timer = $WeaknessTimer
@onready var effects_animated_2d: AnimatedSprite2D = $Effects

@onready var timer_text: Label = $"../Timer/text"
@onready var timer: CanvasLayer = $"../Timer"

@onready var swing_sound: AudioStreamPlayer2D = $SwingSound
@onready var blast_sound: AudioStreamPlayer2D = $BlastSound
@onready var teleport_sound: AudioStreamPlayer2D = $TeleportSound

const BLAST = preload("uid://bmwqn6cc4xxcm")
const TARGET_CURSOR = preload("res://assets/images/crosshair.png") 

const MAX_AMMO = 4
const TIME_TO_HEAL = 10

var blast_cooldown = 0.5
var staff_damage = 1

var max_ammo = 3
var current_ammo = 3
var weakened_count = 0

var can_fire = true

var is_disabled = false
var is_weakened = false
var is_reloading = false
var is_attacking = false
var is_blasting = false
var is_targeting_teleport = false 

var original_ammo_bar_bg_style: StyleBoxFlat
var ammo_bar_bg_style: StyleBoxFlat
var damage_tween: Tween

func _ready() -> void:
	original_ammo_bar_bg_style = ammo_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
	ammo_bar_bg_style = original_ammo_bar_bg_style.duplicate() as StyleBoxFlat
	
	ammo_bar_bg_style.bg_color = Color.RED

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_action_just_pressed("attack") and not is_attacking and not is_blasting and not is_targeting_teleport:
		physical_attack(direction)
		return
		
	if Input.is_action_pressed("blast_mode") and not is_attacking and not is_disabled:
		is_blasting = true
		velocity = Vector2.ZERO
		fire_blast(direction)
	else:
		is_blasting = false
	
		if is_attacking:
			velocity = Vector2.ZERO

		else:
			if direction:
				velocity = direction * SPEED
			else:
				velocity = velocity.move_toward(Vector2.ZERO, SPEED)

		update_animation(direction)
	
	if timer.visible and not weakness_timer.is_stopped():
		timer_text.text = str(int(ceil(weakness_timer.time_left)))
			
	move_and_slide()

func update_animation(direction: Vector2):
	if is_attacking or is_blasting: return
	if direction != Vector2.ZERO:
		animated_sprite.play("move")
		
		if direction.x < 0:
			animated_sprite.flip_h = true
		elif direction.x > 0:
			animated_sprite.flip_h = false

	else:
		animated_sprite.play("idle")

func physical_attack(direction: Vector2):
	is_attacking = true
	swing_sound.play()

	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false

	animated_sprite.play("physical")
	await animated_sprite.animation_finished
	check_collisions()
	is_attacking = false

func check_collisions():
	var bodies = staff_radius.get_overlapping_bodies()
	
	for body in bodies:
		if is_instance_valid(body) and body is RigidBody2D and body.is_in_group("noise_maker"):
			if "is_annihilated" in body and body.is_annihilated:
				continue
			body.take_damage(global_position, staff_damage)
			GameManager.current_score += 2

func fire_blast(aim_direction: Vector2):

	if aim_direction == Vector2.ZERO:
		animated_sprite.play("standing")
		return
		
	if is_weakened:
		if current_ammo <= 0:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
							
			if can_fire:
				can_fire = false
				await get_tree().create_timer(blast_cooldown).timeout
				can_fire = true
			return
			
	var anim_name = "horizontal_blast"
	var flip = false
	
	if aim_direction.y < 0:
		anim_name = "top_corner_blast"
	elif aim_direction.y > 0:
		anim_name = "bottom_corner_blast"
	else:
		anim_name = "horizontal_blast"
		
	if aim_direction.x < 0:
		flip = true
	elif aim_direction.x > 0:
		flip = false
	else:
		flip = animated_sprite.flip_h

	animated_sprite.flip_h = flip
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

	if can_fire:
		can_fire = false
		
		var blast = BLAST.instantiate()
		
		var offset = aim_direction * 50.0
		blast.position = global_position + offset
		blast.velocity = aim_direction.normalized()
		
		blast.rotation = aim_direction.angle()
		
		get_parent().add_child(blast)
		blast_sound.play()
		
		if is_weakened:
			current_ammo -= 1
			ammo_bar.value = current_ammo
			
			if not is_reloading:
				reload_ammo()
		
		await get_tree().create_timer(blast_cooldown).timeout
			
		can_fire = true

func take_weakness():
	weakened_count += 1
	
	if weakened_count > 4:
		weakened_count = 4
		
	is_weakened = true
	ammo_bar.visible = true
	
	if weakened_count == 1:
		max_ammo = 3
	elif weakened_count == 2:
		max_ammo = 2
	elif weakened_count == 3:
		max_ammo = 1
	else:
		is_disabled = true
		
	if damage_tween:
		damage_tween.kill()
		
	damage_tween = create_tween()
	damage_tween.tween_property(animated_sprite, "modulate", Color.RED, 0.15)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.15)
	
	effects_animated_2d.visible = true
	effects_animated_2d.play("weakness")
	await effects_animated_2d.animation_finished
	effects_animated_2d.visible = false
	
	GameManager.trigger_tutorial.emit(
			"pixie_dust",
			"You've Been Hit By Pixie Dust!\n\nPress 'P' to Buy Healing Potion.",
			"P" 
		)

	
	if not is_disabled:
		ammo_bar.max_value = max_ammo
		current_ammo = clamp(current_ammo, 0, max_ammo)
		ammo_bar.value = current_ammo
		
		if current_ammo < max_ammo and not is_reloading:
			reload_ammo()
	else:
		ammo_bar.add_theme_stylebox_override("background", ammo_bar_bg_style)
		ammo_bar.value = 0

	weakness_timer.start(TIME_TO_HEAL * weakened_count)
	timer.visible = true

func reload_ammo():
	is_reloading = true
	
	await get_tree().create_timer(2.0).timeout
	
	if is_weakened and not is_disabled:
		current_ammo = clamp(current_ammo + 1, 0, max_ammo)
		ammo_bar.value = current_ammo
		
		if current_ammo < max_ammo:
			reload_ammo()
		else:
			is_reloading = false
	else:
		is_reloading = false

func _on_weakness_timer_timeout() -> void:
	is_weakened = false
	is_disabled = false
	can_fire = true
	weakened_count = 0
	max_ammo = MAX_AMMO
	current_ammo = MAX_AMMO
	ammo_bar.visible = false
	is_reloading = false
	ammo_bar.add_theme_stylebox_override("background", original_ammo_bar_bg_style)
	timer.visible = false

func heal():
	if not is_weakened:
		return
		
	weakness_timer.stop()
	
	is_weakened = false
	is_disabled = false
	can_fire = true
	weakened_count = 0
	max_ammo = MAX_AMMO
	current_ammo = MAX_AMMO
	is_reloading = false
	
	ammo_bar.visible = false
	timer.visible = false
	ammo_bar.add_theme_stylebox_override("background", original_ammo_bar_bg_style)


func _on_staff_radius_body_entered(body: Node2D) -> void:
	if body.is_in_group("noise_maker"):
		GameManager.trigger_tutorial.emit(
			"close_goblin",
			"Goblin Closing In!\n\nPress 'A' to Bash it with your staff.",
			"A" 
		)

func activate_teleport_mode():
	is_targeting_teleport = true
	
	Input.set_custom_mouse_cursor(TARGET_CURSOR, Input.CURSOR_ARROW, Vector2(16, 16))

func _unhandled_input(event: InputEvent) -> void:
	if is_targeting_teleport and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_targeting_teleport = false
			
			Input.set_custom_mouse_cursor(null)
			
			execute_teleport(get_global_mouse_position())
			get_viewport().set_input_as_handled()

func execute_teleport(target_pos: Vector2):
	is_disabled = true
	velocity = Vector2.ZERO
	
	var tween = create_tween()
	teleport_sound.play()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	global_position = target_pos
	
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	is_disabled = false
