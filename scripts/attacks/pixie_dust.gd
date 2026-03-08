extends Area2D

var velocity = Vector2.ZERO
var speed = 250.0

func _physics_process(delta: float) -> void:
	position += velocity * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Attendant": 
		if body.has_method("take_weakness"):
			body.take_weakness()
			
		queue_free()
