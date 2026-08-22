extends GutTest

func test_density_validation() -> void:
	var gen := BoardGenerator.new(8, 8, 10)
	assert_true(gen.validate_density(10, 8, 8), "10 minas en 8x8 (15.6%) es válido")
	assert_false(gen.validate_density(4, 8, 8), "4 minas en 8x8 (6.25%) es demasiado bajo")
	assert_false(gen.validate_density(20, 8, 8), "20 minas en 8x8 (31.25%) es demasiado alto")

func test_protected_zone_bounds() -> void:
	var gen := BoardGenerator.new(8, 8, 10)
	
	# Esquina
	var corner_zone := gen.get_protected_zone(Vector2i(0, 0), 8, 8)
	assert_eq(corner_zone.size(), 4, "La zona protegida en esquina debe tener 4 celdas")
	
	# Borde
	var edge_zone := gen.get_protected_zone(Vector2i(0, 3), 8, 8)
	assert_eq(edge_zone.size(), 6, "La zona protegida en borde debe tener 6 celdas")
	
	# Centro
	var center_zone := gen.get_protected_zone(Vector2i(3, 3), 8, 8)
	assert_eq(center_zone.size(), 9, "La zona protegida en el centro debe tener 9 celdas")

func test_guaranteed_generation_no_guess() -> void:
	var gen := BoardGenerator.new(8, 8, 10, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	
	var first_click := Vector2i(3, 3)
	var board := gen.generate_board(first_click, rng)
	
	assert_eq(board.total_mines, 10)
	
	# Verificar que ninguna casilla de la zona protegida contenga mina
	var protected_zone := gen.get_protected_zone(first_click, 8, 8)
	for pos in protected_zone:
		assert_false(board.get_cell(pos).is_mine, "La celda protegida %s no debe ser mina" % str(pos))
	
	# Verificar que el primer click sea un 0 (apertura de cascada limpia)
	assert_eq(board.get_cell(first_click).neighbor_mines, 0, "El primer click debe tener 0 minas vecinas")
	
	# Verificar que el solucionador confirme que es 100% resoluble sin adivinar
	var solver := MinesweeperSolver.new()
	var result := solver.solve(board, first_click)
	assert_true(result.is_solvable, "El tablero generado con ensure_solvable debe ser 100% resoluble")
