extends PanelContainer

@onready var message_label: Label = $VBoxContainer/Message
@onready var continue_label: Label = $VBoxContainer/Continue

var blink_tween: Tween

func _ready() -> void:
	visible = false
	GameManager.trigger_tutorial.connect(_on_trigger_tutorial)
	start_blinking()

func start_blinking():
	if blink_tween:
		blink_tween.kill()
		
	blink_tween = create_tween().set_loops()
	
	blink_tween.tween_property(continue_label, "modulate:a", 0.0, 0.6)
	blink_tween.tween_property(continue_label, "modulate:a", 1.0, 0.6)

func _on_trigger_tutorial(tutorial_id: String, message: String):
	if GameManager.seen_tutorials.has(tutorial_id) and GameManager.seen_tutorials[tutorial_id] == true:
		return
		
	GameManager.seen_tutorials[tutorial_id] = true
	
	message_label.text = message
	visible = true
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				visible = false
				get_tree().paused = false
				
				get_viewport().set_input_as_handled()
