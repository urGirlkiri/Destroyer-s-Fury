extends Node2D

@onready var nap_meter: ProgressBar = $GameInfoLayer/NapMeter

var nap_level = 5

func _physics_process(delta: float) -> void:
	
	if (GameManager.current_noise_level <= 25):
		nap_level += delta
	else:
		nap_level -= delta
		
	nap_meter.value = nap_level
	
#todo: implement the yummy shop with beerus yummy stuff when he sleep talks

#todo: implement the item shop with time freeze , time rewind...abilities
