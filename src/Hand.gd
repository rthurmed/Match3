extends Node2D


func _input(event):
	if event is InputEventMouseButton:
		var animate = "hold" if event.pressed else "default"
		$AnimatedSprite.play(animate)
	pass


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _process(delta):
	global_position = get_global_mouse_position()

