class_name BoardGenerator
extends RefCounted

## Rango de densidad recomendado según especificación (12% a 22%)
const MIN_RECOMMENDED_DENSITY: float = 0.12
const MAX_RECOMMENDED_DENSITY: float = 0.22

var width: int = 8
var height: int = 8
var total_mines: int = 10
var ensure_solvable: bool = true
var max_attempts: int = 300

var solver: MinesweeperSolver = MinesweeperSolver.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(p_width: int = 8, p_height: int = 8, p_total_mines: int = 10, p_ensure_solvable: bool = true) -> void:
	width = p_width
	height = p_height
	total_mines = p_total_mines
	ensure_solvable = p_ensure_solvable
	rng.randomize()

func validate_density(p_mines: int, p_width: int, p_height: int) -> bool:
	var area: float = float(p_width * p_height)
	if area <= 0:
		return false
	var density: float = float(p_mines) / area
	return density >= MIN_RECOMMENDED_DENSITY and density <= MAX_RECOMMENDED_DENSITY

func create_empty_board() -> BoardData:
	return BoardData.new(width, height)

func get_protected_zone(first_click: Vector2i, p_width: int, p_height: int) -> Array[Vector2i]:
	var protected_cells: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var pos := first_click + Vector2i(dx, dy)
			if pos.x >= 0 and pos.x < p_width and pos.y >= 0 and pos.y < p_height:
				protected_cells.append(pos)
	return protected_cells

func populate_mines(board: BoardData, first_click: Vector2i, p_rng: RandomNumberGenerator = null) -> bool:
	var use_rng: RandomNumberGenerator = p_rng if p_rng != null else rng
	var protected_zone := get_protected_zone(first_click, board.width, board.height)
	
	var available_coords: Array[Vector2i] = []
	for y in range(board.height):
		for x in range(board.width):
			var pos := Vector2i(x, y)
			if not protected_zone.has(pos):
				available_coords.append(pos)
	
	if available_coords.size() < total_mines:
		push_error("No hay suficientes celdas disponibles para colocar %d minas fuera de la zona protegida." % total_mines)
		return false
	
	for i in range(available_coords.size() - 1, 0, -1):
		var j := use_rng.randi_range(0, i)
		var temp := available_coords[i]
		available_coords[i] = available_coords[j]
		available_coords[j] = temp
	
	for pos: Vector2i in board.cells.keys():
		var cell: CellData = board.cells[pos]
		cell.is_mine = false
		cell.state = CellData.State.HIDDEN
		cell.neighbor_mines = 0
	
	for i in range(total_mines):
		var mine_pos: Vector2i = available_coords[i]
		var cell: CellData = board.cells[mine_pos]
		cell.is_mine = true
	
	board.calculate_neighbor_numbers()
	return true

func generate_board(first_click: Vector2i, p_rng: RandomNumberGenerator = null) -> BoardData:
	var use_rng: RandomNumberGenerator = p_rng if p_rng != null else rng
	var board := create_empty_board()
	
	if not ensure_solvable:
		populate_mines(board, first_click, use_rng)
		return board
	
	var attempts := 0
	var last_result: SolverResult = null
	
	while attempts < max_attempts:
		attempts += 1
		populate_mines(board, first_click, use_rng)
		
		last_result = solver.solve(board, first_click)
		
		if last_result.is_solvable:
			for cell: CellData in board.cells.values():
				cell.state = CellData.State.HIDDEN
			return board
	
	push_warning("BoardGenerator: Se alcanzó el límite de %d intentos sin encontrar tablero perfecto No-Guess. Entregando el último generado." % max_attempts)
	for cell: CellData in board.cells.values():
		cell.state = CellData.State.HIDDEN
	return board
