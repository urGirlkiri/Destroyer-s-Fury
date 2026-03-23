extends PanelContainer

@onready var message_label: Label = $VBoxContainer/Message
@onready var continue_label: Label = $VBoxContainer/Continue

var blink_tween: Tween
var expected_key: String = ""

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

func _on_trigger_tutorial(tutorial_id: String, message: String, required_key: String = ""):
	if GameManager.seen_tutorials.has(tutorial_id) and GameManager.seen_tutorials[tutorial_id] == true:
		return
		
	GameManager.seen_tutorials[tutorial_id] = true
	
	expected_key = required_key.to_upper()
	
	message_label.text = message
	
	if expected_key == "":
		continue_label.text = "[ Press Any Key to Continue ]"
	else:
		continue_label.text = "[ Press " + expected_key + " to Continue ]"
		
	modulate.a = 0.0 
	visible = true
	get_tree().paused = true

	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
		
	var should_dismiss = false
	
	if expected_key != "":
		if event is InputEventKey and event.as_text_keycode() == expected_key:
			should_dismiss = true
	else:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
			should_dismiss = true
			
	if should_dismiss:
		expected_key = "WAITING" 

		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(self, "modulate:a", 0.0, 0.15)

		await fade_out_tween.finished

		visible = false
		get_tree().paused = false
		get_viewport().set_input_as_handled()
