class_name BoardData
extends RefCounted

const DIRECTIONS_8: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0),                   Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
]

var width: int = 8
var height: int = 8
var total_mines: int = 0
var cells: Dictionary = {} # Vector2i -> CellData

func _init(p_width: int = 8, p_height: int = 8) -> void:
	width = p_width
	height = p_height
	cells.clear()
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			cells[pos] = CellData.new(pos, false)

func is_valid_coord(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_cell(pos: Vector2i) -> CellData:
	return cells.get(pos, null)

func get_neighbors(pos: Vector2i, include_diagonals: bool = true) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS_8:
		if not include_diagonals and (dir.x != 0 and dir.y != 0):
			continue
		var neighbor_pos := pos + dir
		if is_valid_coord(neighbor_pos):
			result.append(neighbor_pos)
	return result

func calculate_neighbor_numbers() -> void:
	total_mines = 0
	for pos: Vector2i in cells.keys():
		var cell: CellData = cells[pos]
		if cell.is_mine:
			total_mines += 1
	
	for pos: Vector2i in cells.keys():
		var cell: CellData = cells[pos]
		if cell.is_mine:
			cell.neighbor_mines = 0
			continue
		
		var count := 0
		for neighbor_pos in get_neighbors(pos):
			var neighbor: CellData = cells[neighbor_pos]
			if neighbor.is_mine:
				count += 1
		cell.neighbor_mines = count

func reveal(pos: Vector2i) -> Array[Vector2i]:
	var newly_revealed: Array[Vector2i] = []
	if not is_valid_coord(pos):
		return newly_revealed
	
	var start_cell := get_cell(pos)
	if start_cell == null or not start_cell.is_hidden():
		return newly_revealed
	
	var queue: Array[Vector2i] = [pos]
	start_cell.reveal()
	newly_revealed.append(pos)
	
	if start_cell.is_mine:
		return newly_revealed
	
	while not queue.is_empty():
		var current_pos: Vector2i = queue.pop_front()
		var current_cell: CellData = cells[current_pos]
		
		if current_cell.neighbor_mines == 0 and not current_cell.is_mine:
			for neighbor_pos in get_neighbors(current_pos):
				var neighbor: CellData = cells[neighbor_pos]
				if neighbor.is_hidden() and not neighbor.is_flagged():
					neighbor.reveal()
					newly_revealed.append(neighbor_pos)
					if neighbor.neighbor_mines == 0 and not neighbor.is_mine:
						queue.append(neighbor_pos)
	
	return newly_revealed

func toggle_flag(pos: Vector2i) -> bool:
	if not is_valid_coord(pos):
		return false
	var cell := get_cell(pos)
	if cell == null:
		return false
	return cell.toggle_flag()

func get_revealed_count() -> int:
	var count := 0
	for cell: CellData in cells.values():
		if cell.is_revealed():
			count += 1
	return count

func get_flagged_count() -> int:
	var count := 0
	for cell: CellData in cells.values():
		if cell.is_flagged():
			count += 1
	return count

func get_hidden_count() -> int:
	var count := 0
	for cell: CellData in cells.values():
		if cell.is_hidden():
			count += 1
	return count

func is_solved() -> bool:
	for cell: CellData in cells.values():
		if not cell.is_mine and not cell.is_revealed():
			return false
	return true

func clone() -> BoardData:
	var copy := BoardData.new(width, height)
	copy.total_mines = total_mines
	for pos: Vector2i in cells.keys():
		var original_cell: CellData = cells[pos]
		copy.cells[pos] = original_cell.clone()
	return copy
