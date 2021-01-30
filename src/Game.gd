extends Node2D


# screen size calc:
# x = (CELL_SPRITE_SIZE + COLUMN_GAP) * CELL_COLS + COLUMN_GAP
# y = (CELL_SPRITE_SIZE + COLUMN_GAP) * CELL_ROWS + COLUMN_GAP

const CELL_ROWS = 7 # x
const CELL_COLS = 7 # y
const CELL_TOTAL = CELL_ROWS * CELL_COLS

const CELL_MIN_VALUE = 0
const CELL_MAX_VALUE = 5
const CELL_EMPTY_VALUE = -1
const SEQUENCE_MIN = 3

const CELL_SPRITE_SIZE = 32

const COLUMN_GAP = 10
const GRID_WIDTH = (CELL_SPRITE_SIZE + COLUMN_GAP) * CELL_COLS + COLUMN_GAP
const GRID_HEIGHT = (CELL_SPRITE_SIZE + COLUMN_GAP) * CELL_ROWS + COLUMN_GAP

#const CELL_REAL_HEIGHT = CELL_SPRITE_SIZE + COLUMN_GAP
const CELL_REAL_HEIGHT = GRID_HEIGHT / CELL_ROWS

onready var Cell = preload("res://src/Cell.tscn")

onready var grid: GridContainer = $Grid

var grid_rect = Rect2(Vector2(0, 0), Vector2(CELL_COLS, CELL_ROWS))
var rng = RandomNumberGenerator.new()
var cells = []
var cell_blocked = []

var valid_directions = [
	Vector2.DOWN,
	Vector2.UP,
	Vector2.LEFT,
	Vector2.RIGHT
]

enum CellMove {
	UP = -CELL_COLS,
	DOWN = CELL_COLS,
	LEFT = -1,
	RIGHT = 1
}


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
		cell.connect("finished_animation", self, "_on_Cell_finished_animation")
		
		cell.id = i
		
		grid.add_child(cell, true)
		cells.insert(i, cell)
		cell_blocked.insert(i, false)
	
	# Generate values
	var sequence_count = 1
	while(sequence_count > 0):
		for id in range(0, CELL_TOTAL):
			cells[id].set_value(get_random_cell_value())
		sequence_count = search_all_sequences()
	
	# Reset blocked
	for id in range(0, CELL_TOTAL):
		cell_blocked[id] = false


func get_random_cell_value():
	return rng.randi_range(CELL_MIN_VALUE, CELL_MAX_VALUE)


func get_cell_position_by_id(id):
	var x = id % CELL_COLS
	var y = id / CELL_ROWS
	return Vector2(x, y)


func get_cell_id_by_position(pos: Vector2):
	return int(pos.y * CELL_ROWS + pos.x)


func is_id_valid(id):
	return id >= 0 and id < CELL_TOTAL


func has_any_blocked_cells():
	for i in cell_blocked:
		if i == true:
			return true
	return false


func switch_values(id1, id2):
	var old_value = cells[id2].value
	cells[id2].set_value(cells[id1].value)
	cells[id1].set_value(old_value)


func search_all_sequences():
	var amount_updated = 0
	
	# Horizontal check
	for i in range(0, CELL_ROWS):
		amount_updated += lock_any_linear_sequence(Vector2(0, i), Vector2.RIGHT)
	
	# Vertical check
	for i in range(0, CELL_COLS):
		amount_updated += lock_any_linear_sequence(Vector2(i, 0), Vector2.DOWN)
	
	return amount_updated


func lock_any_linear_sequence(origin, step):
	var needle = origin
	var sequence = []
	var last_value = CELL_EMPTY_VALUE
	var amount_updated = 0
	
	while(grid_rect.has_point(needle)):
		var needle_id = get_cell_id_by_position(needle)
		
		if cell_blocked[needle_id] || cells[needle_id].value != last_value:
			amount_updated += lock_sequence(sequence)
			sequence.clear()
		
		needle += step
		sequence.append(needle_id)
		last_value = cells[needle_id].value
	
	amount_updated += lock_sequence(sequence)
	return amount_updated


func lock_sequence(sequence):
	if sequence.size() < SEQUENCE_MIN:
		return 0
	
	for id in sequence:
#		cells[i].highlight = true
		cells[id].set_value(CELL_EMPTY_VALUE)
		cell_blocked[id] = true
	
	return sequence.size()


func pull_down_cells():
	# If is pulling down usually means sequences have been formed
	$Audio/Pop.play()
	
	var col_falling = [] # How much cells of a column should fall
	
	# Calculate the fall force to every column
	for x in range(0, CELL_COLS):
		col_falling.insert(x, 0)
		for y in range(0, CELL_ROWS):
			var id = x + CellMove.DOWN * y
			if cell_blocked[id]:
				col_falling[x] += 1
	
	# Apply force
	for x in range(0, CELL_COLS):
		var fall_power = col_falling[x]
		if fall_power > 0:
			for yi in range(0, CELL_ROWS):
				# Read from the bottom of the column
				var y = (CELL_ROWS - yi) - 1
				var id = x + CellMove.DOWN * y
				var new_id = x + CellMove.DOWN * (y + fall_power)
				var fall = Vector2(0, fall_power * -1) * (CELL_SPRITE_SIZE + COLUMN_GAP)
				
				# Only switch if the target position is empty
				if is_id_valid(new_id) and cells[new_id].value == CELL_EMPTY_VALUE:
					switch_values(id, new_id)
					cells[new_id].move_sprite_from_to(fall)
	
	# Fill the empty ones
	for x in range(0, CELL_COLS):
		var fall_power = col_falling[x]
		if fall_power > 0:
			for y in range(0, CELL_ROWS):
				var id = x + CellMove.DOWN * y
				var fall = Vector2(0, fall_power * -1) * (CELL_SPRITE_SIZE + COLUMN_GAP)
				
				if cells[id].value == CELL_EMPTY_VALUE:
					cells[id].set_value(get_random_cell_value())
					cells[id].move_sprite_from_to(fall)


func _on_Cell_finished_animation(id):
	cell_blocked[id] = false
	if not has_any_blocked_cells():
		var updated = search_all_sequences()
		if updated > 0:
			pull_down_cells()


func _on_Cell_dropped(id, dir):
	var caller_pos = get_cell_position_by_id(id)
	var target_pos = caller_pos + dir
	var target_id = get_cell_id_by_position(target_pos)
	
	# Ignores input if target is outside or has any blocked cells
	if not grid_rect.has_point(target_pos) or has_any_blocked_cells():
		return
	
	switch_values(id, target_id)
	
	var amount_updated = search_all_sequences()
	
	# Switch back if no sequence where formed
	if amount_updated < 1:
		switch_values(id, target_id)
		return
	
	pull_down_cells()
