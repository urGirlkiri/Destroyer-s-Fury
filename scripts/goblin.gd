extends NoiseMaker

const PIXIE_DUST = preload("uid://85tsfux1tgjo")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var can_throw_dust = true
var is_hit = false

var zig_zag_strength = 2.0 
var time_alive = 0.0
var knockback_force = 600.0 

func _ready():
	super() 
	movement_speed = 120.0 
	mass = 1.0
	linear_damp = 1.0 
	stun_time = 0.4

func _physics_process(delta: float) -> void:
	
	if is_hit:
		linear_velocity = Vector2.ZERO
		return
	
	animated_sprite.play('idle')
	time_alive += delta
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	var direction = get_direction_to_target()
		
	var zig_zag = direction.orthogonal() * sin(time_alive * 10.0) * zig_zag_strength
	
	var final_velocity = (direction + zig_zag).normalized() * movement_speed
	
	linear_velocity = final_velocity
	
	if linear_velocity.x < 0: 
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
	
	if distance_to_target <= 103:
		animated_sprite.play('attack')
		await animated_sprite.animation_finished
		GameManager.current_noise_level += 15
	
	var attendant = get_tree().get_first_node_in_group("player")
	var dist_to_attendant = global_position.distance_to(attendant.global_position)
	
	if dist_to_attendant < 300 and can_throw_dust:
		if randf() < 0.01: 
			throw_pixie_dust()
		
func take_blow(pos: Vector2, damage: int):
	is_hit = true
	GameManager.current_score += 3

	knockback_force *= damage
	
	var knockback_direction = (global_position - pos).normalized()
	
	apply_central_impulse(knockback_direction * knockback_force)
	
	await get_tree().create_timer(stun_time).timeout
	is_hit = false
	
func die():
	if is_annihilated:
		return
		
	is_annihilated = true
	collision_shape.set_deferred("disabled", true)
	
	linear_velocity = Vector2.ZERO
	set_physics_process(false)
	
	animated_sprite.play("die")
	await animated_sprite.animation_finished

	call_deferred("spawn_coin")
	queue_free()

func throw_pixie_dust():
	can_throw_dust = false
	
	var dust = PIXIE_DUST.instantiate()
	var player = get_tree().get_first_node_in_group("player")
	var camera = get_viewport().get_camera_2d()
	
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2(10, -10), 0.05)
		tween.tween_property(camera, "offset", Vector2(-10, 10), 0.05)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
	
	dust.global_position = global_position
	dust.velocity = (player.global_position - global_position).normalized()
	
	get_parent().add_child(dust)
	
	await get_tree().create_timer(5.0).timeout
	can_throw_dust = true
