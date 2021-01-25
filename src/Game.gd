extends Node2D


# screen size calc = (BUG_SIZE + COLUMN_GAP) * BUG_COLS + COLUMN_GAP

const CELL_ROWS = 8
const CELL_COLS = 8
const CELL_TOTAL = CELL_ROWS * CELL_COLS
const CELL_MIN_VALUE = 0
const CELL_MAX_VALUE = 5
const CELL_EMPTY_VALUE = -1
const SEQUENCE_MIN = 3

onready var Cell = preload("res://src/Cell.tscn")

onready var grid: GridContainer = $Grid

var grid_rect = Rect2(Vector2(0, 0), Vector2(CELL_COLS, CELL_ROWS))
var rng = RandomNumberGenerator.new()
var cells = []

var valid_directions = [
	Vector2.DOWN,
	Vector2.UP,
	Vector2.LEFT,
	Vector2.RIGHT
]


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
		
		cell.value = get_random_cell_value()
		cell.id = i
		
		grid.add_child(cell, true)
		cells.insert(i, cell)


func get_random_cell_value():
	return rng.randi_range(CELL_MIN_VALUE, CELL_MAX_VALUE)


func get_cell_position_by_id(id):
	var x = id % CELL_COLS
	var y = id / CELL_ROWS
	return Vector2(x, y)


func get_cell_id_by_position(pos: Vector2):
	return int(pos.y * CELL_ROWS + pos.x)


func switch_values(id1, id2):
	var old = cells[id2].value
	cells[id2].set_value(cells[id1].value)
	cells[id1].set_value(old)


func check_possible_sequences(id):
	var pos = get_cell_position_by_id(id)
	
	# Vertical check
	var sequence_v = search_linear_sequence(id, Vector2(pos.x, 0), Vector2.DOWN)
	
	# Horizontal check
	var sequence = search_linear_sequence(id, Vector2(0, pos.y), Vector2.RIGHT)
	
	if sequence_v.size() > sequence.size():
		sequence = sequence_v
	
	if sequence.size() < SEQUENCE_MIN:
		return
	
	clean_sequence(sequence)
	pull_cells_down()
	fill_empty_cells()


func search_linear_sequence(cell_id, origin, step):
	var needle = origin
	var sequence = []
	
	var cell_value = cells[cell_id].value
	
	while(grid_rect.has_point(needle)):
		var needle_id = get_cell_id_by_position(needle)
		
		# Accumulate the tile sequences
		if cells[needle_id].value == cell_value:
			sequence.append(needle_id)
		elif sequence.has(cell_id):
			return sequence
		else:
			sequence.clear()
		
		needle += step
	
	return sequence


func clean_sequence(sequence):
	for id in sequence:
		cells[id].set_value(CELL_EMPTY_VALUE)


func pull_cells_down():
	# Reads from end to start and ignores last row
	for i in range(CELL_COLS, CELL_TOTAL):
		var id = CELL_TOTAL - i - 1
		var pos = get_cell_position_by_id(id)
		var bot_id = get_cell_id_by_position(pos + Vector2.DOWN)
		
		# Keep pulling the cell down if over empty tile
		while(cells.size() > bot_id and cells[bot_id].value == CELL_EMPTY_VALUE):
			switch_values(id, bot_id)
			pos += Vector2.DOWN
			id = get_cell_id_by_position(pos)
			bot_id = get_cell_id_by_position(pos + Vector2.DOWN)


func fill_empty_cells():
	for id in range(0, CELL_TOTAL):
		if cells[id].value == CELL_EMPTY_VALUE:
			cells[id].set_value(get_random_cell_value())


func _on_Cell_dropped(id, dir):
	var caller_pos = get_cell_position_by_id(id)
	var target_pos = caller_pos + dir
	var target_id = get_cell_id_by_position(target_pos)
	
	if not grid_rect.has_point(target_pos):
		return
	
	switch_values(id, target_id)
	
	check_possible_sequences(id)
	check_possible_sequences(target_id)
