class_name NoiseMaker extends RigidBody2D

@export var movement_speed: float = 100.0
@export var noise_volume: float = 10.0
@export var score_bonus: int = 5

@export var health: int = 3
@export var stun_time: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var progress_bar: ProgressBar = $ProgressBar
 
var target: Node2D
var is_annihilated = false
var current_health: int
var flash_tween: Tween

func _ready():
	current_health = health
	target = get_tree().get_first_node_in_group("Destroyer")
	
	linear_velocity = get_direction_to_target() * movement_speed
	
func _process(_delta: float) -> void:
	var h_perc: float = 0.0
	if health > 0:
		h_perc = float(current_health) / health * 100.0
	progress_bar.value = clamp(h_perc, 0, 100)
	
	if current_health <= 0:
		die()
		
func get_direction_to_target() -> Vector2:
	if target and is_instance_valid(target):
		return (target.global_position - global_position).normalized()
	return Vector2.ZERO

func take_damage(source_position: Vector2):
	if is_annihilated:
		return

	flash_white()
	take_blow(source_position)
	current_health -= 1
	animated_sprite.play('damage')
	if current_health <= 0:
		die()

func take_blow(pos: Vector2):
	pass

func flash_white():
	if flash_tween:
		flash_tween.kill()
	
	flash_tween = create_tween()
	
	var smaterial = animated_sprite.material as ShaderMaterial
	
	smaterial.set_shader_parameter("flash_modifier", 1.0)
	
	flash_tween.tween_method(
		func(value): smaterial.set_shader_parameter("flash_modifier", value),
		1.0, 
		0.0,
		0.6
	)

func die():
	if is_annihilated:
		return
	is_annihilated = true
	(animated_sprite.material as ShaderMaterial).set_shader_parameter("flash_modifier", 0.0)
	queue_free()
