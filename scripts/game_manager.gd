extends Node

signal game_paused(is_paused: bool)
signal game_over_triggered
signal apply_item_effect(id: String)
signal failed_purchase()
signal pause_game()
signal trigger_tutorial(tutorial_id: String, message: String, required_key: String)
signal wave_changed(new_wave: int)

var is_time_frozen = false

const TIME_TO_FREEZE = 6

@export var current_noise_level := 0
@export var current_wave := 1
@export var current_score := 0
@export var current_coins := 0

@export var nap_level = 100.0

@export var yummy_stuff = [
	{
		"id": "pudding",
		"name": "Pudding",
		"desc": "Slow Awakening",
		"price": 30,
		"icon": "res://assets/images/Food/76_pudding_dish.png",
		"sfx": "yummy",
	},
	{
		"id": "cake",
		"name": "Strawberry Cake",
		"desc": "Deep Sleep",
		"price": 60,
		"icon": "res://assets/images/Food/91_strawberrycake_dish.png",
		"sfx": "chew_soft",
	},
	{
		"id": "ramen",
		"name": "Ramen",
		"desc": "Big Nap",
		"price": 100,
		"icon": "res://assets/images/Food/87_ramen.png",
		"sfx": "slurp",
		"quote": "YUMMY! *slurp*"
	}
]

@export var powerups = [
	{
		"id": "healing",
		"name": "Potion",
		"desc": "Restore Energy",
		"price": 25,
		"icon": "res://assets/images/Powerups/potion.png",
		"sfx": "powerup"
	},
	{
		"id": "portal",
		"name": "Teleport",
		"desc": "Teleport away from danger",
		"price": 40,
		"icon": "res://assets/images/Powerups/portal.png"
	},
	{
		"id": "time",
		"name": "Time Freeze",
		"desc": "Stop Time 6s",
		"price": 80,
		"icon": "res://assets/images/Powerups/time.png" 
	}
]

@export var seen_tutorials = {
	"welcome": false,
	"first_goblin": false,
	"close_goblin": false,
	"pixie_dust": false,
	"shop": false,
	"cheat": false,
	"teleport" : false
}

#Cheat Code

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		current_coins += 1000
		GameManager.trigger_tutorial.emit(
		"cheat",
		"CHEAT ACTIVATED: +1000 Coins!",
		""
		)
