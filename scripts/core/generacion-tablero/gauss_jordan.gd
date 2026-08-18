class_name GaussJordanSolver
extends RefCounted

const EPSILON: float = 1e-5

static func to_rref(matrix: Array, num_vars: int) -> Array:
	var rows: int = matrix.size()
	if rows == 0 or num_vars == 0:
		return matrix
	
	var rref_matrix: Array = []
	for r in range(rows):
		var row_copy: Array[float] = []
		for c in range(matrix[r].size()):
			row_copy.append(float(matrix[r][c]))
		rref_matrix.append(row_copy)
	
	var pivot_row: int = 0
	for col in range(num_vars):
		if pivot_row >= rows:
			break
		
		var best_row: int = pivot_row
		var best_val: float = abs(rref_matrix[pivot_row][col])
		
		for r in range(pivot_row + 1, rows):
			var val: float = abs(rref_matrix[r][col])
			if val > best_val:
				best_val = val
				best_row = r
		
		if best_val < EPSILON:
			continue
		
		if best_row != pivot_row:
			var temp = rref_matrix[pivot_row]
			rref_matrix[pivot_row] = rref_matrix[best_row]
			rref_matrix[best_row] = temp
		
		var pivot_val: float = rref_matrix[pivot_row][col]
		for c in range(num_vars + 1):
			rref_matrix[pivot_row][c] /= pivot_val
			if abs(rref_matrix[pivot_row][c]) < EPSILON:
				rref_matrix[pivot_row][c] = 0.0
		
		for r in range(rows):
			if r != pivot_row:
				var factor: float = rref_matrix[r][col]
				if abs(factor) >= EPSILON:
					for c in range(num_vars + 1):
						rref_matrix[r][c] -= factor * rref_matrix[pivot_row][c]
						if abs(rref_matrix[r][c]) < EPSILON:
							rref_matrix[r][c] = 0.0
		
		pivot_row += 1
	
	return rref_matrix

## Analiza las filas en RREF y deduce qué variables binarias xj in {0, 1}
## tienen valor determinado inequívoco (0 = Segura, 1 = Mina).
## Retorna Dictionary con:
## {
##    "safe_vars": Array[int],
##    "mine_vars": Array[int]
## }
static func find_certainties(rref_matrix: Array, num_vars: int) -> Dictionary:
	var safe_set: Dictionary = {}
	var mine_set: Dictionary = {}
	
	for row_idx in range(rref_matrix.size()):
		var row: Array = rref_matrix[row_idx]
		var b_val: float = row[num_vars]
		
		# Identificar coeficientes no nulos
		var pos_indices: Array[int] = []
		var neg_indices: Array[int] = []
		var sum_pos: float = 0.0
		var sum_neg: float = 0.0
		
		for col in range(num_vars):
			var coeff: float = row[col]
			if coeff > EPSILON:
				pos_indices.append(col)
				sum_pos += coeff
			elif coeff < -EPSILON:
				neg_indices.append(col)
				sum_neg += coeff
		
		var total_active := pos_indices.size() + neg_indices.size()
		if total_active == 0:
			continue
		
		var max_lhs: float = sum_pos
		var min_lhs: float = sum_neg
		
		if abs(b_val - max_lhs) < EPSILON:
			for idx in pos_indices:
				mine_set[idx] = true
			for idx in neg_indices:
				safe_set[idx] = true
		
		if abs(b_val - min_lhs) < EPSILON:
			for idx in pos_indices:
				safe_set[idx] = true
			for idx in neg_indices:
				mine_set[idx] = true
	
	var safe_list: Array[int] = []
	for k in safe_set.keys():
		safe_list.append(int(k))
	
	var mine_list: Array[int] = []
	for k in mine_set.keys():
		mine_list.append(int(k))
	
	return {
		"safe_vars": safe_list,
		"mine_vars": mine_list
	}
