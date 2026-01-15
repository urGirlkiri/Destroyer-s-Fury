extends Area2D

var collected = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == 'Attendant' and not collected:
		collected = true
		GameManager.current_coins += 1
		call_deferred("queue_free")
