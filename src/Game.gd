extends Node2D


# screen size calc = (BUG_SIZE + COLUMN_GAP) * BUG_COLS + COLUMN_GAP

const CELL_ROWS = 8
const CELL_COLS = 8
const CELL_TOTAL = CELL_ROWS * CELL_COLS
const CELL_MIN_VALUE = 0
const CELL_MAX_VALUE = 5
const CELL_EMPTY_VALUE = -1

onready var Cell = preload("res://src/Cell.tscn")

onready var grid: GridContainer = $Grid

var rng = RandomNumberGenerator.new()
var cells = []


func _ready():
	rng.randomize()
	build_grid()


func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("reset"):
		# warning-ignore:return_value_discarded
		get_tree().reload_current_scene()


func build_grid():
	for i in range(0, CELL_TOTAL):
		var cell = Cell.instance()
		cell.connect("dropped", self, "_on_Cell_dropped")
		
		cell.value = rng.randi_range(CELL_MIN_VALUE, CELL_MAX_VALUE)
		cell.id = i
		
		grid.add_child(cell, true)
		cells.insert(i, cell)


func get_cell_position_by_id(id):
	var x = id % CELL_COLS
	var y = id / CELL_ROWS
	return Vector2(x, y)


func get_cell_id_by_position(pos: Vector2):
	return pos.y * CELL_ROWS + pos.x


func _on_Cell_dropped(id, dir):
	var caller_pos = get_cell_position_by_id(id)
	var target_pos = caller_pos + dir
	var target_id = get_cell_id_by_position(target_pos)
	
	# switch values
	var old = cells[target_id].value
	cells[target_id].set_value(cells[id].value)
	cells[id].set_value(old)
	
	print(caller_pos, " + ", dir, " = ", target_pos, "; ", id, " => ", target_id)
	
	# TODO: Clean adjacent tiles
