extends StaticBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func play_anim(anim_name: String):
	
	if anim.animation == anim_name:
		return
	
	anim.play(anim_name)
