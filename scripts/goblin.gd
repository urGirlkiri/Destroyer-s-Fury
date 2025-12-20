extends NoiseMaker
		 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var zig_zag_strength = 2.0 
var time_alive = 0.0

func _ready():
	super() 
	movement_speed = 120.0 
	mass = 1.0
	linear_damp = 1.0 

func _physics_process(delta: float) -> void:
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
	
func die():
	collision_shape.set_deferred("disabled", true)
	
	linear_velocity = Vector2.ZERO
	set_physics_process(false)
	
	animated_sprite.play("die")
	await animated_sprite.animation_finished
	await get_tree().create_timer(1.0).timeout
	# GameManager.current_score += score_bonus

	queue_free()
