class_name NoiseMaker extends RigidBody2D

@export var movement_speed: float = 100.0
@export var noise_volume: float = 10.0
@export var score_bonus: int = 5

@export var health: int = 3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var target: Node2D
var is_annihilated = false

func _ready():
	target = get_tree().get_first_node_in_group("Destroyer")
	
	linear_velocity = get_direction_to_target() * movement_speed
	
func _process(_delta: float) -> void:
	if health <= 0 and not is_annihilated:
		
		die()
		is_annihilated = true
		
func get_direction_to_target() -> Vector2:
	if target and is_instance_valid(target):
		return (target.global_position - global_position).normalized()
	return Vector2.ZERO

func take_damage():
	health -= 1
	#animated_sprite.play('damage')
	if health <= 0:
		die()

func die():
	queue_free()
