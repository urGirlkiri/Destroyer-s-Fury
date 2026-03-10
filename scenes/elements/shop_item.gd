extends PanelContainer

signal item_clicked(id: String, price: int)

@onready var image: TextureRect = $MarginContainer/HBoxContainer/Image
@onready var item_name: Label = $MarginContainer/HBoxContainer/Details/Name
@onready var description: Label = $MarginContainer/HBoxContainer/Details/Description
@onready var price: Label = $MarginContainer/HBoxContainer/Details/Price

@onready var color_rect: ColorRect = $ColorRect

var item_id = ""
var item_price = 0

const COLOR_NORMAL = Color(1, 1, 1, 0.0)
const COLOR_HOVER = Color(1, 1, 1, 0.15)
const COLOR_PRESSED = Color(1, 0.8, 0.2, 0.3)

var is_hovered = false

func _ready() -> void:
	color_rect.color = COLOR_NORMAL

func setup(data: Dictionary):
	item_id = data["id"]
	item_price = data["price"]
	
	item_name.text = data["name"]
	description.text = data["desc"]
	price.text = "—  " + str(data["price"]) + " Coins"
	image.texture = load(data["icon"])


func _on_mouse_entered() -> void:
	is_hovered = true
	color_rect.color = COLOR_HOVER

func _on_mouse_exited() -> void:
	is_hovered = false
	color_rect.color = COLOR_NORMAL

func _on_focus_entered() -> void:
	color_rect.color = COLOR_HOVER

func _on_focus_exited() -> void:
	if not is_hovered:
		color_rect.color = COLOR_NORMAL

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			color_rect.color = COLOR_PRESSED
		else:
			color_rect.color = COLOR_HOVER if is_hovered else COLOR_NORMAL
			
			if is_hovered:
				emit_signal("item_clicked", item_id, item_price)
