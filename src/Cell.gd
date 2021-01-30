extends Control


const TWEEN_SPEED = 1
const SPRITE_SIZE = 32
const COL_GAP = 10
const MOVE_LIMIT = SPRITE_SIZE + COL_GAP

onready var sprite: Sprite = $Center/Sprite
onready var tween: Tween = $Tween

export var value = 0
export var id = 0
export var highlight = false

var selected = false
var initial_sprite_position = Vector2(0, 0)
var follow = Vector2()

var valid_directions = [
	Vector2.DOWN,
	Vector2.UP,
	Vector2.LEFT,
	Vector2.RIGHT
]

signal dropped(id, dir)
signal finished_animation(id)


func _input(event):
	if selected and event is InputEventMouseMotion:
		sprite.position += event.relative
		sprite.position.x = clamp(sprite.position.x, -MOVE_LIMIT, MOVE_LIMIT)
		sprite.position.y = clamp(sprite.position.y, -MOVE_LIMIT, MOVE_LIMIT)


func _ready():
	update_sprite()
	$IdLabel.text = str(id)


func _process(_delta):
	sprite.z_index = 100 if selected else 1
	sprite.scale = Vector2.ONE * (1.25 if selected else 1.0)
	
	if tween.is_active():
		sprite.position = follow
#		sprite.position = sprite.position.linear_interpolate(follow, 0.075)
	
	var color = Color.white
	if highlight:
		color = Color.red
	modulate = color


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_WM_MOUSE_EXIT:
		if selected:
			selected = false
			sprite.position = Vector2.ZERO


func set_value(v):
	value = v
	update_sprite()


func update_sprite():
	sprite.region_rect.position.x = sprite.region_rect.size.x * value


func move_sprite_from_to(from: Vector2, to: Vector2 = Vector2.ZERO):
	var duration = (to.y - from.y) * 0.8 / 64
	# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "follow", from, to, duration, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	# warning-ignore:return_value_discarded
	tween.start()
	sprite.position = from


func _on_Cell_gui_input(event: InputEvent):
	if event.is_action_pressed("click"):
		selected = true
	
	if event.is_action_released("click"):
		selected = false
		
		var dir = sprite.position.normalized().round()
		if valid_directions.has(dir):
			emit_signal("dropped", id, dir)
		
		sprite.position = Vector2.ZERO


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "die":
		emit_signal("finished_animation", id)


func _on_Tween_tween_all_completed():
	follow = Vector2(0, 0)
	sprite.position = Vector2.ZERO
	emit_signal("finished_animation", id)
