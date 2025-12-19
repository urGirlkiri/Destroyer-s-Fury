class_name NoiseMaker extends RigidBody2D

@export var movement_speed: float = 100.0
@export var noise_volume: float = 10.0
@export var health: int = 3

var target: Node2D

func _ready():
	target = get_tree().get_first_node_in_group("Destroyer")
	
	linear_velocity = get_direction_to_target() * movement_speed
	
func _process(_delta: float) -> void:
	if health <= 0:
		die()

func get_direction_to_target() -> Vector2:
	if target and is_instance_valid(target):
		return (target.global_position - global_position).normalized()
	return Vector2.ZERO

func take_damage():
	health -= 1
	if health <= 0:
		die()

func die():
	queue_free()
