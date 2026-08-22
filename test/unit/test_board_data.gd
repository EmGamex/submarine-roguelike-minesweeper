extends GutTest

func test_board_initialization() -> void:
	var board := BoardData.new(8, 8)
	assert_eq(board.width, 8)
	assert_eq(board.height, 8)
	assert_eq(board.cells.size(), 64)
	assert_eq(board.get_hidden_count(), 64)
	assert_eq(board.get_revealed_count(), 0)
	assert_eq(board.get_flagged_count(), 0)

func test_neighbors_calculation() -> void:
	var board := BoardData.new(8, 8)
	
	# Esquina (0,0) debe tener 3 vecinos
	var corner_neighbors := board.get_neighbors(Vector2i(0, 0))
	assert_eq(corner_neighbors.size(), 3, "La esquina debe tener 3 vecinos")
	
	# Borde (1,0) debe tener 5 vecinos
	var edge_neighbors := board.get_neighbors(Vector2i(1, 0))
	assert_eq(edge_neighbors.size(), 5, "El borde debe tener 5 vecinos")
	
	# Centro (3,3) debe tener 8 vecinos
	var center_neighbors := board.get_neighbors(Vector2i(3, 3))
	assert_eq(center_neighbors.size(), 8, "El centro debe tener 8 vecinos")

func test_reveal_and_cascade() -> void:
	var board := BoardData.new(4, 4)
	# Tablero vacío sin minas: un click en (0,0) debe revelar todo el tablero de 16 celdas
	var revealed := board.reveal(Vector2i(0, 0))
	assert_eq(revealed.size(), 16)
	assert_eq(board.get_revealed_count(), 16)
	assert_true(board.is_solved())

func test_flag_toggle() -> void:
	var board := BoardData.new(4, 4)
	var pos := Vector2i(1, 1)
	
	board.toggle_flag(pos)
	assert_true(board.get_cell(pos).is_flagged())
	assert_eq(board.get_flagged_count(), 1)
	
	board.toggle_flag(pos)
	assert_false(board.get_cell(pos).is_flagged())
	assert_eq(board.get_flagged_count(), 0)
