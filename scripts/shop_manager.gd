extends Node

@onready var yummy_shop: Panel = $YummyShop
@onready var yummy_shop_list: VBoxContainer = $YummyShop/Items/VBoxContainer

@onready var power_shop: Panel = $PowerShop
@onready var power_shop_list: VBoxContainer = $PowerShop/Items/VBoxContainer

const SHOP_ITEM = preload("uid://cegs1nif11y3e")

var is_game_over  = false

func _ready() -> void:
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_over_triggered.connect(_on_game_over)
	
	for item_data in GameManager.yummy_stuff:
		var new_item = SHOP_ITEM.instantiate()
		yummy_shop_list.add_child(new_item)
		new_item.setup(item_data)
		new_item.item_clicked.connect(_on_shop_item_clicked)
		
	for item_data in GameManager.powerups:
		var new_item = SHOP_ITEM.instantiate()
		power_shop_list.add_child(new_item)
		new_item.setup(item_data)
		new_item.item_clicked.connect(_on_shop_item_clicked)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("yummy"):
		toggle_yummy_shop()

	if event.is_action_pressed("powerup"):
		toggle_power_shop()

func _on_game_paused(is_paused: bool):
	if not is_paused:
		yummy_shop.visible = false
		power_shop.visible = false

func _on_game_over():
	yummy_shop.visible = false
	power_shop.visible = false
	is_game_over = true

func toggle_yummy_shop():
	if is_game_over: return
	
	yummy_shop.visible = not yummy_shop.visible
	power_shop.visible = false
	
func toggle_power_shop():
	if is_game_over: return
	
	power_shop.visible = not power_shop.visible
	yummy_shop.visible = false

func _on_yummy_btn_pressed() -> void:
	toggle_yummy_shop()

func _on_power_btn_pressed() -> void:
	toggle_power_shop()

func _on_shop_item_clicked(id: String, price: int):
	if GameManager.current_coins >= price:
		GameManager.current_coins -= price
		apply_item_effect(id)
	else:
		print("Not enough coins!")

func apply_item_effect(id: String):
	print("Applying item effect: ", id)
	
	match id:
		"pudding":
			GameManager.nap_level += 20.0
		"cake":
			GameManager.nap_level += 40.0
		"ramen":
			GameManager.nap_level = 100.0
		"healing":
			pass
		"portal":
			print("TODO: Implement Teleport")
		"time":
			print("TODO: Implement Time Freeze")
		_:
			print("Unknown item bought: ", id)
			
	GameManager.nap_level = clamp(GameManager.nap_level, 0, 100)
