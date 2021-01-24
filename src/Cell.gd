extends Control


onready var sprite: Sprite = $Center/Sprite
onready var tween: Tween = $Tween

export var value = 0
export var id = 0
var selected = false
var initial_sprite_position = Vector2(0, 0)
var valid_directions = [
	Vector2.DOWN,
	Vector2.UP,
	Vector2.LEFT,
	Vector2.RIGHT
]

signal dropped(id, dir)


func _input(event):
	if selected and event is InputEventMouseMotion:
		sprite.position += event.relative
		sprite.position.x = clamp(sprite.position.x, -42, 42)
		sprite.position.y = clamp(sprite.position.y, -42, 42)


func _ready():
	update_sprite()


func _process(_delta):
	sprite.z_index = 100 if selected else 1
	sprite.scale = Vector2.ONE * (1.25 if selected else 1.0)

func set_value(v):
	value = v
	update_sprite()


func update_sprite():
	sprite.region_rect.position.x = sprite.region_rect.size.x * value


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_WM_MOUSE_EXIT:
		selected = false
		sprite.position = Vector2.ZERO


func _on_Cell_gui_input(event: InputEvent):
	if event.is_action_pressed("click"):
		selected = true
	
	if event.is_action_released("click"):
		selected = false
		
		var dir = sprite.position.normalized().round()
		if valid_directions.has(dir):
			emit_signal("dropped", id, dir)
		
		sprite.position = Vector2.ZERO
