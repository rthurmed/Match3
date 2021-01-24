extends Node2D


# screen size calc = (BUG_SIZE + COLUMN_GAP) * BUG_COLS + COLUMN_GAP

const CELL_ROWS = 8
const CELL_COLS = 8
const CELL_TOTAL = CELL_ROWS * CELL_COLS
const CELL_MIN_VALUE = 0
const CELL_MAX_VALUE = 5
const CELL_EMPTY_VALUE = -1

onready var Cell = preload("res://src/Cell.tscn")

var rng = RandomNumberGenerator.new()
var cells = []


func _ready():
	rng.randomize()
	build_grid()


func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()


func build_grid():
	for i in range(0, CELL_TOTAL):
		var cell = Cell.instance()
		
		cell.value = rng.randi_range(CELL_MIN_VALUE, CELL_MAX_VALUE)
		cell.id = i
		
		$Grid.add_child(cell, true)
		cells.insert(i, cell)
