extends GutTest

func test_gauss_jordan_rref_basic() -> void:
	# Sistema:
	# x0 + x1 = 2
	# x0 + 0  = 1
	# Solución esperada: x0 = 1, x1 = 1
	var matrix: Array = [
		[1.0, 1.0, 2.0],
		[1.0, 0.0, 1.0]
	]
	var rref := GaussJordanSolver.to_rref(matrix, 2)
	assert_almost_eq(rref[0][0], 1.0, 0.001)
	assert_almost_eq(rref[0][1], 0.0, 0.001)
	assert_almost_eq(rref[0][2], 1.0, 0.001)
	assert_almost_eq(rref[1][0], 0.0, 0.001)
	assert_almost_eq(rref[1][1], 1.0, 0.001)
	assert_almost_eq(rref[1][2], 1.0, 0.001)

func test_gauss_jordan_all_mines_deduction() -> void:
	# Ecuación: x0 + x1 = 2 (ambas deben ser minas)
	var matrix: Array = [
		[1.0, 1.0, 2.0]
	]
	var rref := GaussJordanSolver.to_rref(matrix, 2)
	var certainties := GaussJordanSolver.find_certainties(rref, 2)
	
	assert_eq(certainties["mine_vars"].size(), 2)
	assert_true(certainties["mine_vars"].has(0))
	assert_true(certainties["mine_vars"].has(1))
	assert_eq(certainties["safe_vars"].size(), 0)

func test_gauss_jordan_all_safes_deduction() -> void:
	# Ecuación: x0 + x1 = 0 (ambas deben ser seguras)
	var matrix: Array = [
		[1.0, 1.0, 0.0]
	]
	var rref := GaussJordanSolver.to_rref(matrix, 2)
	var certainties := GaussJordanSolver.find_certainties(rref, 2)
	
	assert_eq(certainties["safe_vars"].size(), 2)
	assert_true(certainties["safe_vars"].has(0))
	assert_true(certainties["safe_vars"].has(1))
	assert_eq(certainties["mine_vars"].size(), 0)

func test_gauss_jordan_subset_subtraction() -> void:
	# Ecuaciones:
	# x0 + x1      = 1
	#      x1 + x2 = 2
	# RREF restará las filas: x0 - x2 = -1 => x0 = 0 (segura), x2 = 1 (mina), x1 = 1 (mina)
	var matrix: Array = [
		[1.0, 1.0, 0.0, 1.0],
		[0.0, 1.0, 1.0, 2.0]
	]
	var rref := GaussJordanSolver.to_rref(matrix, 3)
	var certainties := GaussJordanSolver.find_certainties(rref, 3)
	
	assert_true(certainties["safe_vars"].has(0), "x0 debe ser deducida como segura")
	assert_true(certainties["mine_vars"].has(1), "x1 debe ser deducida como mina")
	assert_true(certainties["mine_vars"].has(2), "x2 debe ser deducida como mina")
