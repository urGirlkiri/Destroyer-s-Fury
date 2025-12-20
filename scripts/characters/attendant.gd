extends CharacterBody2D

const SPEED = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var staff_radius: Area2D = $StaffRadius

var is_attacking = false

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		physical_attack(direction)
		return
		
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
			body.take_damage()
			GameManager.current_score += 2
