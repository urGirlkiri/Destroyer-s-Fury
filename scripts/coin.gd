extends Area2D

@onready var sound: AudioStreamPlayer2D = $Sound

var collected = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == 'Attendant' and not collected:
		collected = true
		GameManager.current_coins += 1
		
		hide()
		
		set_deferred("monitoring", false)
		
		sound.play()
		await sound.finished
		
		queue_free()
