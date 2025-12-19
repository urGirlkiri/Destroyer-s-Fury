extends NoiseMaker

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var zig_zag_strength = 2.0 
var has_target = false
var time_alive = 0.0

func _ready():
	super() 
	movement_speed = 250.0 
	mass = 1.0
	linear_damp = 1.0 

func _physics_process(delta: float) -> void:
	time_alive += delta
	
	var direction = get_direction_to_target()
	
	var zig_zag = direction.orthogonal() * sin(time_alive * 10.0) * zig_zag_strength
	
	var final_velocity = (direction + zig_zag).normalized() * movement_speed
	
	linear_velocity = final_velocity
		
	if linear_velocity.x < 0: 
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
func die():
	linear_velocity = Vector2.ZERO
	set_physics_process(false)
	
	animated_sprite.play("die")
	await animated_sprite.animation_finished
	
	queue_free()
