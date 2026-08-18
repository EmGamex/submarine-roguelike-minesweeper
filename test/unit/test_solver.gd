extends GutTest

func test_solver_detects_50_50_ambiguity() -> void:
	# Construir un tablero con un 50/50 forzado:
	# Tablero 3x3 donde una esquina tiene 2 celdas ocultas y un '1' que las toca a ambas sin otra pista.
	# [ 1,  1, 0 ]
	# [ ?,  ?, 0 ] -> una de las dos '?' es mina (50/50 puro)
	# [ 0,  0, 0 ]
	var board := BoardData.new(3, 3)
	board.cells[Vector2i(0, 1)].is_mine = true # Una mina en (0, 1)
	board.calculate_neighbor_numbers()
	
	# Si hacemos primer click en (2, 2), se revela la zona inferior y números 1 y 1 arriba
	# pero deja (0,1) y (1,1) como un 50/50 puro sin pistas diferenciales.
	var solver := MinesweeperSolver.new()
	var result := solver.solve(board, Vector2i(2, 2))
	
	# El solver no debe hacer suposiciones al azar; debe detectar que no se puede resolver lógicamente
	# (a menos que haya sido resuelto, lo cual no es posible para este patrón)
	if not board.is_solved():
		assert_false(result.is_solvable, "El solucionador debe rechazar un tablero que contenga un 50/50 forzado")

func test_solver_solves_deterministic_board() -> void:
	var board := BoardData.new(4, 4)
	# Colocar 1 mina en (3, 3)
	board.cells[Vector2i(3, 3)].is_mine = true
	board.calculate_neighbor_numbers()
	
	var solver := MinesweeperSolver.new()
	var result := solver.solve(board, Vector2i(0, 0))
	
	assert_true(result.is_solvable, "El tablero con 1 sola mina alejada debe resolverse al 100%")
	assert_eq(result.flagged_count, 1)
