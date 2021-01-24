extends Control


onready var sprite: Sprite = $Center/Sprite
export var value = 0
export var id = 0
var selected = false
var initial_sprite_position = Vector2(0, 0)


func _input(event):
	if selected and event is InputEventMouseMotion:
		sprite.position += event.relative


func _ready():
	update_sprite()


func _process(_delta):
	sprite.z_index = 100 if selected else 1
	sprite.scale = Vector2.ONE * (1.5 if selected else 1.0)

func set_value(v):
	value = v
	update_sprite()


func update_sprite():
	sprite.region_rect.position.x = sprite.region_rect.size.x * value


func _on_Cell_gui_input(event: InputEvent):
	if event.is_action_pressed("click"):
		selected = true
	
	if event.is_action_released("click"):
		selected = false
		sprite.position = Vector2.ZERO
