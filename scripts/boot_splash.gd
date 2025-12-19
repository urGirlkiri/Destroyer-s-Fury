extends Control

const MAIN_GAME_SCENE = preload("uid://dtkxfqikwcg8l")

@export var fade_duration: float = 0.5

const DIM_DISTANCE = 580.0 
const END_LIMIT = 600.0 

@onready var progress_bar: TextureProgressBar = $ProgressBar
@onready var glowhead: TextureRect = $ProgressBar/Glowhead

func _ready() -> void:
	modulate.a = 1.0 
	progress_bar.value = 0
	
	glowhead.position.y = (progress_bar.size.y / 2) - (glowhead.size.y / 2) + 3.5
	
	start_loading_animation()

func _process(_delta: float) -> void:
	var percent = 0.0
	
	if progress_bar.max_value > 0:
		percent = progress_bar.value / progress_bar.max_value
	
	var bar_width = progress_bar.size.x
	var target_x = percent * bar_width
	
	glowhead.position.x = target_x - (glowhead.size.x / 2)
	
	var start_dim_x = END_LIMIT - DIM_DISTANCE
	
	if glowhead.position.x >= END_LIMIT:
		glowhead.modulate.a = 0.0
	elif glowhead.position.x > start_dim_x:
		var distance_into_fade = glowhead.position.x - start_dim_x
		var opacity = 1.0 - (distance_into_fade / DIM_DISTANCE)
		glowhead.modulate.a = opacity
	else:
		glowhead.modulate.a = 1.0

func start_loading_animation() -> void:
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) 
	tween.finished.connect(_on_loading_complete)

func _on_loading_complete() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(_change_to_main_scene)

func _change_to_main_scene() -> void:
	get_tree().change_scene_to_packed(MAIN_GAME_SCENE)
