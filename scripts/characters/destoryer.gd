extends StaticBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var woke_up = false

func play_anim(anim_name: String):

	woke_up = true if anim.animation == 'awake' else false
	
	if anim.animation == anim_name and not woke_up:
		return
	
	anim.play(anim_name)
