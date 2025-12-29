extends Area2D

var velocity = Vector2.ZERO
var speed = 700.0
var damage = 2

func _physics_process(delta: float) -> void:
	position += velocity * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("noise_maker"):
		if body.has_method("take_damage"):
			body.take_damage(global_position, damage)
			
		queue_free() 

func _on_screen_exited() -> void:
	queue_free()
