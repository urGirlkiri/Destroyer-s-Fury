extends CharacterBody2D

const SPEED = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var staff_radius: Area2D = $StaffRadius

const BLAST = preload("uid://bmwqn6cc4xxcm")

var blast_cooldown = 0.5
var staff_damage = 1

var is_attacking = false
var is_blasting = false
var can_fire = true

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_action_just_pressed("ui_accept") and not is_attacking and not is_blasting:
		physical_attack(direction)
		return
		
	if Input.is_action_pressed("blast_mode") and not is_attacking:
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
		
		await get_tree().create_timer(blast_cooldown).timeout
		can_fire = true
